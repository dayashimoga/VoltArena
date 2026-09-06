import struct, json

for name in ['blaster_repeater.glb', 'blaster.glb']:
    path = 'assets/models/weapons/' + name
    with open(path, 'rb') as f:
        f.read(12)
        chunk_len = struct.unpack('<I', f.read(4))[0]
        f.read(4)
        data = json.loads(f.read(chunk_len).decode('utf-8'))
        print(f"=== {name} ===")
        print("Nodes:", data.get("nodes"))
        for i, acc in enumerate(data.get("accessors", [])):
            if "min" in acc and "max" in acc and len(acc["min"]) == 3:
                print(f"  Pos: min={acc['min']}, max={acc['max']}")
