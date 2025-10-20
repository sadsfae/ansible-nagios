#!/usr/bin/python3
# original QUADS nagios check located here:
# https://github.com/quadsproject/nagios-quads-checks/tree/main/validation-check

import argparse
import sys
import requests
from datetime import datetime, timezone, timedelta
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class AssignmentCheck:
    def __init__(self, host, time_cutoff):
        self.assignments = []
        self.clouds = []
        self.exit_code = 0
        self.host = f"https://{host}/api/v3/"
        self.schedules = []
        self.time_cutoff = time_cutoff

    def _request(self, resource, params={}):
        try:
            r = requests.get(
                self.host + resource, params=params, timeout=100, verify=False
            )
            r.raise_for_status()
            return r.json()
        except requests.exceptions.RequestException as error:
            self.output_results(3, str(error))

    def output_results(self, code: int, message: str = ""):
        nagios_states = {
            0: "OK - All assignments validated",
            1: "WARNING",
            2: "CRITICAL - Assignments not validated for clouds:",
            3: "UNKNOWN - Request error:",
        }

        print(f"{nagios_states[code]} {message}")
        sys.exit(code)

    def get_assignments(self):
        self.assignments = self._request(
            "assignments", params={"active": "true", "validated": "false"}
        )

    def get_schedules(self):
        self.schedules = self._request(
            "schedules",
            params={
                "assignment_id__in": ",".join([str(x["id"]) for x in self.assignments])
            },
        )

    def check_assignments(self):
        self.get_assignments()
        if self.assignments:
            self.get_schedules()

            for schedule in self.schedules:
                cloud = schedule["assignment"]["cloud"]["name"]
                if cloud not in self.clouds:
                    diff = datetime.now(timezone.utc) - datetime.strptime(
                        schedule["start"], "%a, %d %b %Y %H:%M:%S %Z"
                    ).replace(tzinfo=timezone.utc)
                    if diff > timedelta(hours=self.time_cutoff):
                        self.clouds.append(cloud)

            if self.clouds:
                self.exit_code = 2

        self.output_results(self.exit_code, ",".join(self.clouds))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-H", "--hostname", required=True, type=str, help="Domain of the target host"
    )
    parser.add_argument(
        "-c", "--time-cutoff", default=2, required=False, type=int, help="Time cutoff in hours"
    )

    args = parser.parse_args()
    checker = AssignmentCheck(args.hostname, args.time_cutoff)
    checker.check_assignments()


if __name__ == "__main__":
    main()
