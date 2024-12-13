
import time, re

from selenium import webdriver
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver import FirefoxOptions
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.firefox.remote_connection import FirefoxRemoteConnection
#from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
from selenium.webdriver.support.ui import Select


def is_element_present(how, what):
    try: 
        driver.find_element(by=how, value=what)
        return True
    except NoSuchElementException as e: 
        return False


def is_alert_present():
    try: 
        driver.switch_to_alert()
        return True
    except NoAlertPresentException as e:
        return False
    return True


def close_alert_and_get_its_text():
    try:
        alert = driver.switch_to_alert()
        alert_text = alert.text
        if accept_next_alert:
            alert.accept()
        else:
            alert.dismiss()
        return alert_text
    finally: 
        accept_next_alert = True


def main():
    base_url = "https://scribe.ac-test.fr:4200"
    verificationErrors = []
    accept_next_alert = True

    # Créer une session Firefox
    # chrome_options = webdriver.ChromeOptions()
    # chrome_options.add_argument('--no-sandbox')
    # driver = webdriver.Chrome('/usr/local/bin/chromedriver', chrome_options=chrome_options)
    
    #firefox_options = webdriver.FirefoxOptions(DesiredCapabilities.firefox())
    firefox_options = webdriver.FirefoxOptions()
    firefox_options.add_argument("--headless")
    driver = webdriver.Firefox(options=firefox_options)
    # driver = webdriver.Remote(command_executor='http://192.168.0.198:4444/wd/hub', desired_capabilities=None, browser_profile=FirefoxRemoteConnection, proxy=None, keep_alive=False, file_detector=None, options=FirefoxOptions)
        
    # addCleanup(driver.quit)
    driver.implicitly_wait(30)
    # driver.maximize_window()
    
    # Appeler l’application web
    print ("go " + base_url)
    driver.get(base_url + "/")
    print ("find scribe")
    driver.find_element_by_link_text("scribe").click()
    print ("clear username")
    driver.find_element_by_id("username").clear()
    print ("send username")
    driver.find_element_by_id("username").send_keys("admin")
    print ("clear password")
    driver.find_element_by_id("password").clear()
    print ("send password")
    driver.find_element_by_id("password").send_keys("Eole12345!")
    driver.find_element_by_id("valider").click()
#    driver.find_element_by_link_text("Outils").click()
    
    # driver.find_element_by_css_selector("#menu_scribe_extraction > span").click()
    # driver.find_element_by_link_text("Importation annuelle des bases").click()
    # driver.find_element_by_link_text("Sconet").click()
    # driver.find_element_by_link_text("Enseignants et personnels administratifs").click()
    # driver.find_element_by_css_selector("#content > div > a").click()
    # driver.find_element_by_css_selector("#content > div > a").click()
    # driver.find_element_by_id("enseignant").clear()
    # driver.find_element_by_id("enseignant").send_keys(u"/mnt/eole-ci-tests/dataset/données_scribe/sts_emp_0210050R_2009.xml")
    # driver.find_element_by_css_selector("input[type=\"submit\"]").click()
    # driver.find_element_by_css_selector("a.simple_link > h1").click()
    # driver.find_element_by_css_selector("a.simple_link > h1").click()
    # assertEqual(u"Importation des comptes en cours, veuillez conserver cette page. Cette opération peut être longue.", close_alert_and_get_its_text())
    # assertEqual("Lecture des fichiers en cours, veuillez conserver cette page.", close_alert_and_get_its_text())
        
    # Saisir et confirmer le mot-clé
    # search_field.send_keys("Mot-clé")
    # search_field.submit()
    
    # Consulter la liste des résultats affichés à la suite de la recherche
    # à l’aide de la méthode find_elements_by_class_name
    # lists= driver.find_elements_by_class_name("_Rm")
    
    # Passer en revue tous les éléments et restituer le texte individuel
    # i=0
    # for listitem in lists:
    #  print (listitem.get_attribute("innerHTML"))
    #  i=i+1
    #  if(i>10):
    #    break
    
    # Fermer la fenêtre du navigateur
    driver.quit()


if __name__ == "__main__":
    main()
