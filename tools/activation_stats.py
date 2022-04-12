#!/usr/bin/env python
import argparse
import logging
import pandas as pd
import re
from collections import defaultdict, namedtuple
from ow import OW


TIMESTAMP_RE = r'\[(?P<timestamp>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d+Z)\]'
TID_RE =  r'\[#tid_(?P<tid>\w+)\]'
HEALTHCHECK_TID = 'sid_invokerHealth'
RegexMapping = namedtuple('RegexMapping', ['regex', 'mapping'])

logger = logging.getLogger(__name__)

class ControllerLogParser:
    def __init__(self):
        # output: key is TID
        # healthcheck: key is ActivationId
        self.output = defaultdict(dict)
        self.healthchecks = defaultdict(dict)

    def handle_tid_regex(self, line, regex, mapping):
        """
        If line matches, recognized groups will be added to `output[tid]` dict according to provided mapping. Regex must have `tid` group.
        """
        if m := re.match(regex, line):
            tid = m.group('tid')
            if tid == HEALTHCHECK_TID:
                dest = self.healthchecks[m.group('activation_id')]
            else:
                dest = self.output[tid]
            for group, dict_key in mapping.items():
                v = m.group(group)
                if dict_key in dest:
                    assert dest[dict_key] == v, line
                else:
                    dest[dict_key] = v
            return True
        else:
            return False
        
    REGEX_MAPPINGS = [
        RegexMapping(
            rf'{TIMESTAMP_RE} \[INFO\] {TID_RE} \[ActionsApi\] action activation id: (?P<activation_id>\w+) \[marker:controller_loadbalancer_start:\d+\]',
            {'timestamp': 'lb_start', 'activation_id': 'activation_id'}),
        RegexMapping(
            rf"{TIMESTAMP_RE} \[INFO\] {TID_RE} \[ShardingContainerPoolBalancer\] scheduled activation (?P<activation_id>\w+), action '(?P<action>[^']+)' \(\w+\), ns '(\w+)', mem limit \d+ MB \(\w+\), time limit \d+ ms \(\w+\) to (?P<invoker>\w+)",
            {'timestamp': 'scheduled', 'activation_id': 'activation_id', 'action': 'action', 'invoker': 'invoker'}),
        RegexMapping(
            rf"{TIMESTAMP_RE} \[INFO\] {TID_RE} \[ShardingContainerPoolBalancer\] posting topic '\w+' with activation id '(?P<activation_id>\w+)' \[marker:controller_kafka_start:\d+\]",
            {'timestamp': 'kafka_send', 'activation_id': 'activation_id'}),
        RegexMapping(
            rf"{TIMESTAMP_RE} \[INFO\] {TID_RE} \[ShardingContainerPoolBalancer\] received result ack for '(?P<activation_id>\w+)'",
            {'timestamp': 'received_result', 'activation_id': 'activation_id'})
    ]

    def handle_line(self, line):
        line = line.rstrip()
        assert re.match(TIMESTAMP_RE, line)

        for regmap in self.REGEX_MAPPINGS:
            if self.handle_tid_regex(line, regmap.regex, regmap.mapping):
                break

    def analyze_activations(self, fn):
        with open(fn) as f:
            for line in f:
                self.handle_line(line)

    def get_result(self):
        for k, v in self.output.items():
            # Safe to run multiple times
            v['tid'] = k
        for k, v in self.healthchecks.items():
            v['tid'] = HEALTHCHECK_TID
            v['activation_id'] = k

        res = list(self.output.values())
        res += list(self.healthchecks.values())
        return pd.DataFrame.from_records(res)

def ow_lookup_activations(activations, wskprops=None, namespace='_') -> pd.DataFrame:
    ow = OW(wskprops)

    records = []
    for i, activation in enumerate(activations):
        try:
            data = ow.fetch_activation(activation, namespace)
            record = {
                'activation_id': data['activationId'],
                'duration': data['duration'],
                'begin': data['start'],
                'end': data['end'],
                'status': data['response'].get('status'),
            }

            for annotation in data['annotations']:
                key, val = annotation['key'], annotation['value']
                if key in ('waitTime', 'timeout'):
                    record[key] = val

            records.append(record)
        except Exception as e:
            logging.error(f'Unable to fetch activation {activation}: {e}, {data}')

        if i % 100 == 0 or True:
            logging.info(f'Got {i} of  {len(activations)} activations')
    return pd.DataFrame.from_records(records)

def process(controller_log, output, wskprops=None, lookup_activations=False):
    parser = ControllerLogParser()
    parser.analyze_activations(controller_log)
    res = parser.get_result()

    if lookup_activations:
        activations = res.activation_id.dropna().drop_duplicates().tolist()
        activation_df = ow_lookup_activations(activations, wskprops)
        res = res.join(activation_df.set_index('activation_id'), on='activation_id')

    res.to_csv(output)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--controller-log', required=True, help='Path to controller.log')
    parser.add_argument('--wskprops', help='OpenWhisk credentials, default: ~/.wskprops')
    parser.add_argument('--lookup-activations', action='store_true'),
    parser.add_argument('--output', required=True)

    args = parser.parse_args()
    process(**vars(args))

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    main()
