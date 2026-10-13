import os
import re
import shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "AXEL", "item_icons_redraw")
DST = os.path.join(ROOT, "AXEL", "axel_project", "combat", "art", "item_icons")
PATTERN = re.compile(r"^\d+_([A-Z]+\d*(?:-[A-Z])?)_.*\.png$")


def main():
    copied = 0
    for name in sorted(os.listdir(SRC)):
        match = PATTERN.match(name)
        if not match:
            continue
        target = os.path.join(DST, match.group(1) + ".png")
        if not os.path.exists(target):
            print("skip, no game icon for " + name)
            continue
        shutil.copyfile(os.path.join(SRC, name), target)
        copied += 1
    print("synced %d icons" % copied)


if __name__ == "__main__":
    main()
