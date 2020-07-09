import json
import pprint
import urllib.request
from urllib.parse import urlparse
import os

def get_tlds():
    f = urllib.request.urlopen("https://publicsuffix.org/list/effective_tld_names.dat")
    content = f.read()
    lines = content.decode('utf-8').split("\n")
    # remove comments
    tlds = [line for line in lines if not line.startswith("//") and not line == ""]
    return tlds

def extract_domain(url, tlds):
    # get domain
    url = url.replace("http://", "").replace("https://", "")
    url = url.split("/")[0]
    # get tld/sld
    parts = url.split(".")
    suffix1 = parts[-1]
    sld1 = parts[-2]
    if len(parts) > 2:
        suffix2 = ".".join(parts[-2:])
        sld2 = parts[-3]
    else:
        suffix2 = suffix1
        sld2 = sld1
    # try the longger first
    if suffix2 in tlds:
        tld = suffix2
        sld = sld2
    else:
        tld = suffix1
        sld = sld1
    return sld + "." + tld

def clean(site, tlds):
    site["domains"] = list(set([extract_domain(url, tlds) for url in site["domains"]]))
    return site

if __name__ == "__main__":
    filename = "testfile.json"

    cache_path = "tlds.json"
    if os.path.exists(cache_path):
        with open(cache_path, "r") as f:
            tlds = json.load(f)
    else:
        tlds = get_tlds()
        with open(cache_path, "w") as f:
            json.dump(tlds, f)

    with open(filename) as f:
        d = json.load(f)
        d = [clean(site, tlds) for site in d]
        pprint.pprint(d)
        with open("clean.json", "w") as f:
            json.dump(d, f)
