#!/usr/bin/env python
# -*- coding: utf-8 -*-

__author__ = "@JeffreyShran"
__version__ = "0.0.1"
__license__ = "MIT"

"""
ACTION LIST

- Add a notes_URL.txt in each folder upon creation with header style:

##################################################
#   OBSERVATIONS
##################################################


"""

import sys, os
import argparse
from urllib.parse import urlsplit
from pathlib import Path

def main(args):
    """ Main entry point of the app """

    # make top level directory variable
    topDir = args.path + args.target

    # Check for dodgy custom paths on argument inputs.
    if not Path(args.path).is_dir():
        sys.exit('The path "%s" specified does not exist' % args.path)

    # Safely create directory, no error raised if exists, does not overwrite existing.
    Path(topDir).mkdir(exist_ok=True)

    # Read URL's from standard input
    for url in sys.stdin:

        parsed = urlsplit(url)

        # catch any urls that can't be split due to no scheme
        if not all([parsed.scheme, parsed.netloc]):
            parsed = urlsplit("https://" + url)

        # This gives us something like "jeff.jeffland.co.uk"
        host = parsed.netloc.rstrip('\n')
        # Create full destination
        destinationDir = topDir + "/" + host
        # Create an empty folder if the host name hasn't already been seen.
        Path(destinationDir).mkdir(exist_ok=True)
        # Progress report
        # print(host)

if __name__ == "__main__":
    """ This is executed when run from the command line """
    # Construct the argument parser and parse the arguments
    ap = argparse.ArgumentParser(
        prog = 'Top One Nice One Get Sorted!',
        description = 'Takes urls on stdin and creates directories based on the netloc, no dupes, no schemes.',
        epilog = 'Usage Idea: httprobe | toponeniceonegetsorted --target paypal')
    ap.add_argument(
        '--version',
        action='version',
        version="%(prog)s (version {version})".format(version=__version__))
    ap.add_argument(
        '-t',
        '--target',
        required = True,
        metavar = 'target',
        type = str,
        help = 'The target working directory. No slash.')
    ap.add_argument(
        '-p',
        '--path',
        required = False,
        metavar = 'path',
        type = str,
        help = 'Top level directory. Give in the format /mnt/mount/folder/',
        default = '/mnt/e/recon_data/programs/')

    args = ap.parse_args()
    main(args)