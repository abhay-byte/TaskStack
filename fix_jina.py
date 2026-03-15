import os
import fileinput

jina_file = "/home/abhay/.local/lib/python3.14/site-packages/openviking/models/embedder/jina_embedders.py"

# Modify the openviking source code directly to inject the truncation parameter to the Jina API call
with fileinput.FileInput(jina_file, inplace=True) as file:
    for line in file:
        print(line.replace("kwargs = {\"input\": text_input, \"model\": self.model_name}", "kwargs = {\"input\": text_input, \"model\": self.model_name}\n        payload[\"truncate\"] = True"), end='')

