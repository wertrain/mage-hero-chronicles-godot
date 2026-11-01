"""Export runtime JSON files from the Depot master database (data.dpo)."""

import json
from pathlib import Path
from typing import Any


DATA_DIR = Path(__file__).resolve().parent
DPO_PATH = DATA_DIR / "data.dpo"


def _resource_path(depot_path: str) -> str:
	"""Convert an image path relative to data.dpo into a Godot resource path."""
	path = str(depot_path or "").replace("\\", "/")
	if not path:
		return ""
	if path.startswith("res://"):
		return path
	marker = "art/"
	if marker in path:
		return "res://" + path[path.index(marker):]
	return path


def _parse_json_text(value: Any, field_name: str) -> Any:
	if isinstance(value, str):
		try:
			return json.loads(value)
		except json.JSONDecodeError as error:
			raise ValueError(f"Invalid JSON in Depot field '{field_name}': {error}") from error
	return value


def _export_line(sheet_name: str, source: dict[str, Any]) -> dict[str, Any]:
	line = dict(source)
	if sheet_name == "card":
		line["art_path"] = _resource_path(line.pop("art", ""))
		tags = line.get("tags", [])
		if isinstance(tags, str):
			line["tags"] = [tag.strip() for tag in tags.split(",") if tag.strip()]
	elif sheet_name in {"enemy", "item"} and line.get("image"):
		line["image"] = _resource_path(line["image"])
	elif sheet_name == "relic":
		line["hook_effects"] = _parse_json_text(line.get("hook_effects", "[]"), "hook_effects")
	return line


def export_sheets(dpo_filepath: str | Path = DPO_PATH) -> None:
	dpo_path = Path(dpo_filepath).resolve()
	with dpo_path.open("r", encoding="utf-8-sig") as file:
		data = json.load(file)

	exported_count = 0
	for sheet in data.get("sheets", []):
		if sheet.get("hidden") or sheet.get("isProps"):
			continue
		sheet_name = str(sheet["name"]).lower()
		lines = [_export_line(sheet_name, line) for line in sheet.get("lines", [])]
		output_path = dpo_path.parent / f"{sheet_name}.json"
		with output_path.open("w", encoding="utf-8", newline="\n") as file:
			json.dump({"lines": lines}, file, ensure_ascii=False, indent="\t")
			file.write("\n")
		exported_count += 1
	print(f"Exported {exported_count} runtime JSON files to {dpo_path.parent}.")


if __name__ == "__main__":
	export_sheets()
