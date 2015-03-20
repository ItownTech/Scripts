import os
import os.path
import requests
import re
from HTMLParser import HTMLParser

class MLStripper(HTMLParser):
    def __init__(self):
        self.reset()
        self.fed = []
    def handle_data(self, d):
        self.fed.append(d)
    def get_data(self):
        return ''.join(self.fed)

def strip_tags(html):
    s = MLStripper()
    s.feed(html)
    return s.get_data()

class GetMeiziPic(object):
    """docstring for ClassName"""
    def __init__(self):
        super(GetMeiziPic, self).__init__()
        self.max = None
        # sample: <img src="http://ww1.sinaimg.cn/mw600/005vbOHfgw1eohghggdpjj30cz0ll0x5.jpg" style="max-width: 486px; max-height: 450px;">
        self.ImgRegex = r'<p><img[^>]*?src\s*=\s*["\']?([^\'" >]+?)[ \'"][^>]*?></p>'
        self._isUrlFormat = re.compile(r'http://([\w-]+\.)+[\w-]+(/[\w\- ./?%&=]*)?');
        self._path = self.DealDir("Images")
        print("===============   start   ===============");

        last = 'last'
        i = 900
        if os.path.exists(last):
            i = int(open(last, 'r').read(1000))
            print 'last', i
        while True:
            print("===============   loading page {0}   ===============".format(i))
            with open('last', 'w') as f:
                f.write(str(i))
            self.DoFetch(i)
            i += 1
            if i > self.max:
                break

        print("===============   end   ===============")
    def DealDir(self, path):
            if not os.path.exists(path):
                os.mkdir(path);
            return path;

    def DoFetch(self, pageNum):
        response = requests.get("http://jandan.net/ooxx/page-{0}#comments".format(pageNum), timeout=5)
        # request.Credentials = CredentialCache.DefaultCredentials;

        if response.status_code != 200: return;
        # stream = response.GetResponseStream();
        if len(response.text) == 0: return;
        if self.max is None:
            self.max = self.get_max(response.text)

        self.FetchLinksFromSource(response.text);

    def get_max(self, html_code):
        m = re.search('.+cp-pagenavi.+', html_code)
        m = re.search('\d+', strip_tags(m.group(0)).strip())
        return int(m.group(0))
    def FetchLinksFromSource(self, htmlSource):
        prog = re.compile(self.ImgRegex, re.IGNORECASE)
        matchesImgSrc = prog.findall(htmlSource)
        for href in matchesImgSrc:
            # only for sina image
            if ".sinaimg." in href and self.CheckIsUrlFormat(href):
                print href
            else:
                continue;

            self.download_file(href)

    def CheckIsUrlFormat(self, value):
        return self._isUrlFormat.match(value) is not None
        
    def download_file(self, url):
        local_filename = "Images/"+ url.split('/')[-1]
        if os.path.exists(local_filename):
            print '\t skip',local_filename
            return
        else:
            print '\t=>',local_filename
        # NOTE the stream=True parameter
        try :
            url = url.replace('.jandan.cf', '')
            r = requests.get(url, timeout=10, stream=True)
            with open(local_filename, 'wb') as f:
                for chunk in r.iter_content(chunk_size=1024): 
                    if chunk: # filter out keep-alive new chunks
                        f.write(chunk)
                        f.flush()
        except Exception as e:
            
            print e
        
        
        return local_filename

if __name__ == '__main__':
    g = GetMeiziPic()