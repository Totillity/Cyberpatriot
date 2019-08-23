import os

import subprocess
import pathlib

import lark

def pretty(tree, indent=0):
    if isinstance(tree, lark.Token):
        if tree != "\n":
            print("    "*indent + tree + "\n")
    else:    
        print("    "*indent + tree.data + "\n")
        for child in tree.children:
            pretty(child, indent+1)


class Data:
    def __init__(self, secpol, audit):
        self.secpol = secpol
        self.audit = audit


class Rule:
    def apply(self, data):
        return 0


class AuditpolRule(Rule):
    def __init__(self, name: str, pol: str, value):
        self.name = name
        self.pol = pol
        self.value = value
    
    def apply(self, data):
        if data.audit.get(self.name, None).strip() == self.pol:
            return self.value
        else:
            return 0


class SeceditRule(Rule):
    def __init__(self, part: str, config: str, test, value: int):
        self.part = part
        self.config = config
        self.test = test
        self.value = value

    def apply(self, data):
        tree = data.secpol
        for part in tree.children:
            if part.children[0] .strip()== self.part:
                for config in part.children[1:]:
                    if not isinstance(config, lark.Token):
                        if config.children[0].strip() == self.config:
                            if self.test(config.children[1]):
                                return self.value
        return 0


def rate(data, rules):
    value = 0

    for rule in rules:
        value += rule.apply(data)    

    return value


def main():
    parser = lark.Lark.open('mu.lark.txt', parser='lalr')

    config_path = pathlib.Path("data.inf")
    result = subprocess.run(["secedit", "/export", "/cfg", str(config_path)])

    with config_path.open("r") as config:
        contents = config.read().encode("utf-8").decode("utf-16")[2:]
    # print(contents)

    config_path.unlink()

    rules = [
        SeceditRule("System Access", "MaximumPasswordAge", lambda a: int(a) < 30, 1),
        AuditpolRule("Logon", "Success", 2)
    ]

    tree = parser.parse(contents)

    auditpol = subprocess.run("auditpol /get /category:*", shell=True, stdout=subprocess.PIPE).stdout.replace(b"\r", b"").decode()
    pol = dict([word for word in line.strip().split("  ") if word] for line in auditpol.splitlines() if line.startswith("  "))

    data = Data(tree, pol)

    rating = rate(data, rules)
    print(rating)


if __name__ == "__main__":
    main()
