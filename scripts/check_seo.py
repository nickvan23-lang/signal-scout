#!/usr/bin/env python3
"""Validate crawlable metadata and local navigation without making indexing claims."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import json
import xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]/'Web'
BASE='https://nickvan23-lang.github.io/signal-scout/'
class Page(HTMLParser):
    def __init__(self):
        super().__init__();self.title='';self.intitle=False;self.h1=0;self.meta={};self.canonical=[];self.links=[];self.images=[];self.ids=set();self.jsons=[];self.injson=False
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if a.get('id'):self.ids.add(a['id'])
        if tag=='title':self.intitle=True
        if tag=='h1':self.h1+=1
        if tag=='meta':self.meta[a.get('name',a.get('property'))]=a.get('content','')
        if tag=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href'))
        if tag in ('a','link') and a.get('href'):self.links.append(a['href'])
        if tag in ('img','source') and a.get('src'):self.links.append(a['src'])
        if tag in ('img','source'):
            for candidate in a.get('srcset','').split(','):
                parts=candidate.strip().split()
                if parts:self.links.append(parts[0])
        if tag=='img':self.images.append(a)
        if tag=='script' and a.get('type')=='application/ld+json':self.injson=True;self.jsons.append('')
    def handle_data(self,data):
        if self.intitle:self.title+=data
        if self.injson:self.jsons[-1]+=data
    def handle_endtag(self,tag):
        if tag=='title':self.intitle=False
        if tag=='script':self.injson=False
pages={}
for f in ROOT.rglob('*.html'):
    p=Page();p.feed(f.read_text());pages[f.resolve()]=p
errors=[];result=[]
indexable={f:p for f,p in pages.items() if 'noindex' not in p.meta.get('robots','').lower()}
expected_urls=set()
for f,p in sorted(indexable.items()):
    name=f.relative_to(ROOT.resolve()).as_posix()
    route='' if name=='index.html' else name.removesuffix('index.html') if name.endswith('/index.html') else name
    expected=BASE+route
    expected_urls.add(expected)
    if not p.title or p.h1!=1:errors.append(f'{name}: missing title or not exactly one H1')
    if p.canonical!=[expected]:errors.append(f'{name}: incorrect canonical')
    if not 60<=len(p.meta.get('description',''))<=200:errors.append(f'{name}: weak/missing description')
    for k in ['og:title','og:description','og:url','og:image','twitter:card']:
        if not p.meta.get(k):errors.append(f'{name}: missing {k}')
    for obj in p.jsons:
        try:json.loads(obj)
        except json.JSONDecodeError as exc:errors.append(f'{name}: invalid JSON-LD: {exc}')
    for a in p.images:
        if 'alt' not in a or not a.get('width') or not a.get('height'):errors.append(f'{name}: image missing alt or dimensions')
    result.append({'page':name,'title':p.title,'title_chars':len(p.title),'description_chars':len(p.meta.get('description','')),'h1':p.h1,'canonical':expected})
for f,p in pages.items():
    for href in p.links:
        u=urlsplit(href)
        if u.scheme or u.netloc:
            if not href.startswith(BASE):continue
            target=(ROOT/unquote(u.path.removeprefix(urlsplit(BASE).path))).resolve()
        else:
            target=(f.parent/unquote(u.path)).resolve() if u.path else f
        if target.is_dir():target=target/'index.html'
        if not target.exists():errors.append(f'{f.name}: missing local link {href}')
        elif u.fragment and target in pages and u.fragment not in pages[target].ids:errors.append(f'{f.name}: missing anchor {href}')
locations=[n.text for n in ET.parse(ROOT/'sitemap.xml').getroot().iter('{http://www.sitemaps.org/schemas/sitemap/0.9}loc')]
if set(locations)!=expected_urls or len(locations)!=len(set(locations)):errors.append('sitemap: must include every indexable page exactly once and exclude noindex pages')
for f,p in pages.items():
    if 'review' in f.relative_to(ROOT.resolve()).parts and 'noindex' not in p.meta.get('robots',''):errors.append(f'{f.relative_to(ROOT.resolve())}: review page must remain noindex')
home=pages[(ROOT/'index.html').resolve()]
if home.meta.get('apple-itunes-app')!='app-id=6810531496':errors.append('home: missing or incorrect Smart App Banner')
store_url='https://apps.apple.com/us/app/signal-scout-ble-finder/id6810531496'
if store_url not in home.links:errors.append('home: missing official App Store download link')
for f,p in indexable.items():
    if any(text in f.read_text().lower() for text in ['app store review in progress','app store review is still in progress','awaiting app store review']):errors.append(f'{f.name}: stale pending-release copy')
if len({p.title for p in pages.values()})!=len(pages):errors.append('duplicate titles')
print(json.dumps({'pages':result,'sitemap_urls':locations,'errors':errors,'passed':not errors},indent=2))
raise SystemExit(bool(errors))
