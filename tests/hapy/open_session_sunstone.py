# pylint: skip-file

from html.parser import HTMLParser
import time, re, sys, os

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
        base_url = "https://hapy.ac-test.fr"
        print( "base_url = " + base_url)
        password_admin= "eole"
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
        service = Service(r'/snap/bin/firefox.geckodriver')
        driver = webdriver.Firefox(options=firefox_options, service=service)
            
        # addCleanup(driver.quit)
        driver.implicitly_wait(10)
        # driver.maximize_window()
        
        # Appeler l’application web
        print ("go " + base_url)
        driver.get(base_url + "/")

        print ("find username")
        username = driver.find_element( by=By.NAME, value="username")
        print ("username = " + username.get_attribute("value"))
        print ("clear username")
        username.clear()
        print ("send username")
        username.send_keys("eoleone")
        print ("find password " + password_admin)
        password= driver.find_element( by=By.ID, value="password")
        print ("clear password")
        password.clear()
        print ("send password")
        password.send_keys(password_admin)
        print ("find login")
        valider = driver.find_element( by=By.ID, value="login_btn")
        print ("click sur login")
        valider.click()
        time.sleep(20)
        
        texte_page = driver.page_source
        if "Tableau de bord" in texte_page:
            print( "Connection OK")
        elif "Invalid username or password" in texte_page:
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
