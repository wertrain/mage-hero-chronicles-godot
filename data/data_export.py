import json

''' 各シートを個別に lines 部分だけをオブジェクト形式でJSONとしてエクスポートする
'''
def export_sheets(dpo_filepath):
    with open(dpo_filepath, 'r') as file:
        data = json.load(file)
    for sheet in data['sheets']:
        sheet_name = sheet['name'].lower()
        lines = sheet.get('lines', [])
        if lines:
            filename = f"{sheet_name}.json"
            with open(filename, 'w') as file:
                json.dump({"lines": lines}, file, indent='\t')
    print("complete.")

export_sheets("data.dpo")
