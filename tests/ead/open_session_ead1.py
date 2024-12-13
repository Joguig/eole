
# pylint: skip-file

from html.parser import HTMLParser
import time, re, sys, os
from packaging.version import Version

from selenium import webdriver
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver import FirefoxOptions
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.firefox.remote_connection import FirefoxRemoteConnection
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.support.ui import Select

# from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
class HTMLFilter(HTMLParser):
    text = ""

    def handle_data(self, data):
        data = "" + data
        data = data.strip()
        if data == "":
            return
        self.text += "   * " 
        self.text += data
        self.text += "\n"


def displayContent(data):
    f = HTMLFilter()
    f.feed(data)
    print(f.text)


def is_element_present(driver, how, what):
    try: 
        driver.find_element(by=how, value=what)
        return True
    except NoSuchElementException as e: 
        return False

def main():
    try:
        if len(sys.argv) > 1:
            base_url = sys.argv[1]
        else:
            base_url = "https://scribe.ac-test.fr:4200"
        print( "base_url = " + base_url)
        if len(sys.argv) > 2:
            click_to = sys.argv[2]
        else:
            click_to = "server"
        print( "click_to = " + click_to)
        if len(sys.argv) > 3:
            vmVersionMajeur = sys.argv[3]
        else:
            vmVersionMajeur = os.getenv('VM_VERSIONMAJEUR', '2.8.1')
        print( "VM_VERSIONMAJEUR = " + vmVersionMajeur)
        if Version(vmVersionMajeur) < Version("2.8.0"):
            password_admin= "eole"
        else:
            password_admin= "Eole12345!"
        verificationErrors = []
        accept_next_alert = True
    
        # Créer une session Firefox
        # chrome_options = webdriver.ChromeOptions()
        # chrome_options.add_argument('--no-sandbox')
        # driver = webdriver.Chrome('/usr/local/bin/chromedriver', chrome_options=chrome_options)
        
        # firefox_options = webdriver.FirefoxOptions(DesiredCapabilities.firefox())
        firefox_options = webdriver.FirefoxOptions()
        firefox_options.log.level = "trace"
        firefox_options.binary_location = "/snap/firefox/current/firefox.launcher"
        firefox_options.add_argument("--headless")
        #profile_path = r'C:\Users\Admin\AppData\Roaming\Mozilla\Firefox\Profiles\s8543x41.default-release'
        #firefox_options.set_preference('profile', profile_path)
        #firefox_options.set_preference('network.proxy.type', 1)
        #firefox_options.set_preference('network.proxy.socks', '127.0.0.1')
        #firefox_options.set_preference('network.proxy.socks_port', 9050)
        #firefox_options.set_preference('network.proxy.socks_remote_dns', False)
        service = Service(r'/snap/bin/firefox.geckodriver')
        driver = webdriver.Firefox(options=firefox_options, service=service )
        print(driver.capabilities["browserVersion"])
        # driver = webdriver.Remote(command_executor='http://192.168.0.198:4444/wd/hub', desired_capabilities=None, browser_profile=FirefoxRemoteConnection, proxy=None, keep_alive=False, file_detector=None, options=FirefoxOptions)
            
        # addCleanup(driver.quit)
        driver.implicitly_wait(10)
        # driver.maximize_window()
        
        # Appeler l’application web
        print ("go " + base_url)
        driver.get(base_url + "/")

        elems = driver.find_elements( by=By.XPATH, value="//a[@href]")
        for elem in elems:
            print("  href= " + str(elem.get_attribute("href")))

        get_title = driver.title
        print("titre atteint = " + get_title) 

        print ("find " + click_to)
        driver.find_element( by=By.LINK_TEXT, value=click_to).click()
        #displayContent(driver.page_source)
        print ("find username/login")
        if is_element_present(driver, "tag name","login"):
            print ("find login ?")
            username = driver.find_element( by=By.NAME, value="login")
        else:
            print ("find username ?")
            username = driver.find_element( by=By.NAME, value="username")
        print ("username = " + username.get_attribute("value"))
        print ("clear username")
        username.clear()
        print ("send username")
        username.send_keys("admin")
        print ("find password " + password_admin)
        password= driver.find_element( by=By.ID, value="password")
        print ("clear password")
        password.clear()
        print ("send password")
        password.send_keys(password_admin)
        print ("find valider")
        valider = driver.find_element( by=By.ID, value="valider")
        print ("click sur valider")
        valider.click()
        time.sleep(10)
        
        texte_page = driver.page_source
        if "VOUS ÊTES CONNECTÉ" in texte_page:
            print( "Connection OK")
        elif "Echec de l'authentification" in texte_page:
            print( "ERREUR: authentification!!")
        else:
            print( "ERREUR: message inconnu !!")
            print( texte_page )
            
         
    except Exception as e:
        print ("-----------------------------")
        print (driver.page_source)
        print ("-----------------------------")
        raise e
    finally:
        # Fermer la fenêtre du navigateur
        print("quit")
        driver.quit()


if __name__ == "__main__":
    main()
