
import sys
import requests

if __name__ == '__main__':
    hostname = sys.argv[1]
    port = int(sys.argv[2])
    r = requests.get('https://zephir.ac-test.fr:7081', auth=('admin_zephir', 'eole'), timeout=10)
    print ( r.status_code )
    print ( r.headers['content-type'] )
    print ( r.encoding)
    print ( r.text )  
