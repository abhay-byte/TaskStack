import json

with open("/home/abhay/.openviking/ov.conf", "r") as f:
    conf = json.load(f)

# Change embedding provider to text-embedding-3-large directly
conf["embedding"]["dense"] = {
  "api_base": "https://api.openai.com/v1",
  "api_key": "YOUR_OPENAI_API_KEY", # Reverting back to standard openai if necessary, but actually we should just try to use Jina with smaller chunking size
  "provider": "openai",
  "model": "text-embedding-3-large",
  "dimension": 3072
}

with open("/home/abhay/.openviking/ov.conf", "w") as f:
    json.dump(conf, f, indent=2)
