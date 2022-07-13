#!/usr/bin/env python
from argparse import ArgumentParser
from configparser import ConfigParser
from flickrapi import FlickrAPI
import sys

def arg_setup():
    parser = ArgumentParser(description='Upload files to Flickr via the API')
    parser.add_argument('-c', '--config-file', default='.flickrrc',
                        help='the path to the configuration file containing Flickr credentials')
    parser.add_argument('-n', '--title', help='the title to give the uploaded file')
    parser.add_argument('-d', '--description', help='the description to give the uploaded file')
    parser.add_argument('-t', '--tag', action='append', help='tag to apply to the uploaded file')
    parser.add_argument('filename', help='the path to the file to upload')
    return parser

if __name__ == '__main__':
    args = arg_setup().parse_args()
    config = ConfigParser()
    config.read(args.config_file)

    tags = map(lambda t: f'"{t}"', args.tag) if args.tag else None

    flickr = FlickrAPI(config['flickr.com']['ApiKey'],
                       config['flickr.com']['ApiKeySecret'],
                       format='parsed-json')
    flickr.authenticate_via_browser(perms='write')
    flickr.upload(args.config_file, title=args.title,
                  description=args.description,
                  tags=' '.join(tags), format='etree')


