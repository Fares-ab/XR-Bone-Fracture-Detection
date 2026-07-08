import os

source_path = r"c:\Users\dedo0\Desktop\XR-Bone-Fracture-Detection-main\frontend\lib\main.dart"
screens_dir = r"c:\Users\dedo0\Desktop\XR-Bone-Fracture-Detection-main\frontend\lib\screens"

if not os.path.exists(screens_dir):
    os.makedirs(screens_dir)

with open(source_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

chunks = [
    ("welcome_page.dart", 216, 465),
    ("login_page.dart", 466, 673),
    ("register_page.dart", 674, 1004),
    ("dashboard_page.dart", 1005, 1343),
    ("profile_page.dart", 1344, 1880),
    ("apply_xray_page.dart", 1881, 2390),
    ("history_page.dart", 2391, 2615),
    ("report_detail_page.dart", 2616, 2843)
]

preamble = """import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../db_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'index.dart';\n\n"""

for filename, start, end in chunks:
    chunk_lines = lines[start-1:end]
    filepath = os.path.join(screens_dir, filename)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(preamble)
        f.writelines(chunk_lines)

index_path = os.path.join(screens_dir, "index.dart")
with open(index_path, 'w', encoding='utf-8') as f:
    for filename, _, _ in chunks:
        f.write(f"export '{filename}';\n")

main_content = lines[0:215]
main_content.insert(8, "import 'screens/index.dart';\n")

with open(source_path, 'w', encoding='utf-8') as f:
    f.writelines(main_content)

print("Refactor completed successfully!")
