"""Command line: the only way QML reaches the data side."""
import argparse
import json
import sys

from . import assets, backup, board, paths, shell, sources, wallpapers


def _print(data) -> None:
    json.dump(data, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")


def cmd_board(args) -> int:
    if args.action == "get":
        try:
            _print({**board.annotate(board.load()), "root": str(paths.root())})
            return 0
        except board.BoardError as e:
            # Still print an empty board so the desktop draws nothing.
            _print(board.empty())
            print(e, file=sys.stderr)
            return 1
    try:
        board.save(json.loads(sys.stdin.read()))
        return 0
    except (json.JSONDecodeError, board.BoardError) as e:
        print(e, file=sys.stderr)
        return 1


def cmd_import(args) -> int:
    try:
        _print(assets.import_image(args.path, remove_bg=not args.keep_background))
        return 0
    except (OSError, assets.AssetError) as e:
        print(e, file=sys.stderr)
        return 1


def cmd_remove(args) -> int:
    try:
        assets.remove(args.asset)
        return 0
    except assets.AssetError as e:
        print(e, file=sys.stderr)
        return 1


def cmd_recut(args) -> int:
    try:
        _print(assets.recut(args.asset))
        return 0
    except (OSError, assets.AssetError) as e:
        print(e, file=sys.stderr)
        return 1


def cmd_assets(args) -> int:
    _print(assets.list_assets())
    return 0


def cmd_source(args) -> int:
    collect = sources.REGISTRY.get(args.name)
    if collect is None:
        print(f"unknown source: {args.name}", file=sys.stderr)
        return 2
    _print(collect())
    return 0


def cmd_export(args) -> int:
    print(backup.export(args.path))
    return 0


def cmd_restore(args) -> int:
    try:
        backup.restore(args.path, replace=args.replace)
        return 0
    except backup.BackupError as e:
        print(e, file=sys.stderr)
        return 1


def cmd_wallpapers(args) -> int:
    _print(wallpapers.current())
    return 0


def cmd_start(args) -> int:
    try:
        shell.start()
        return 0
    except shell.ShellError as e:
        print(e, file=sys.stderr)
        return 1


def cmd_edit(args) -> int:
    try:
        shell.edit()
        return 0
    except shell.ShellError as e:
        print(e, file=sys.stderr)
        return 1


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="deskpaper", description="With no command, opens the editor.")
    p.set_defaults(func=cmd_edit)
    sub = p.add_subparsers(dest="command")
    sub.add_parser("start", help="show the stickers on the desktop").set_defaults(func=cmd_start)
    sub.add_parser("edit", help="open the editor (starts the stickers too)").set_defaults(
        func=cmd_edit)
    b = sub.add_parser("board", help="read or write board.json")
    b.add_argument("action", choices=("get", "set"))
    b.set_defaults(func=cmd_board)
    i = sub.add_parser("import", help="import a picture and make its die-cut")
    i.add_argument("path")
    i.add_argument("--keep-background", action="store_true",
                   help="do not make a flat background transparent")
    i.set_defaults(func=cmd_import)
    rc = sub.add_parser("recut", help="make the flat background of an imported picture transparent")
    rc.add_argument("asset")
    rc.set_defaults(func=cmd_recut)
    sub.add_parser("assets", help="list imported pictures").set_defaults(func=cmd_assets)
    rm = sub.add_parser("remove", help="delete an imported picture no sticker uses")
    rm.add_argument("asset")
    rm.set_defaults(func=cmd_remove)
    s = sub.add_parser("source", help="print a data source as JSON")
    s.add_argument("name")
    s.set_defaults(func=cmd_source)
    e = sub.add_parser("export", help="save board, pictures and data to a .tar.gz")
    e.add_argument("path")
    e.set_defaults(func=cmd_export)
    r = sub.add_parser("restore", help="bring back a .tar.gz from export")
    r.add_argument("path")
    r.add_argument("--replace", action="store_true", help="keep the current one aside")
    r.set_defaults(func=cmd_restore)
    sub.add_parser("wallpapers", help="picture shown on each screen").set_defaults(
        func=cmd_wallpapers)
    return p


def main(argv=None) -> int:
    args = parser().parse_args(argv)
    return args.func(args)
