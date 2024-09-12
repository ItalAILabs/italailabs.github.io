Changes (09-09-24)

- Added two collaborators to people.html

- Changed the structure of accelerating.html

- Fixed an href error in research.html


-


Changes (09-09-24)

- Added all remaining pictures and descriptions to people.html, removed placeholder links

- Made changes to send-email.php, also made changes to the config.example file to reflect them

- Made minor changes to research, contact and success


-


Changes (06-09-24)

- Made changes to the layout and added two partners to partners.html

- Made it so a an outline appears when hovering over a person's image (or clicking it in mobile)

- Added two projects to research.html

- Put the correct account in the twitter feedline in index.html

- Swapped out the old twitter icon with the one in index.html and people.html


-


Changes (04-09-24)

- Added the twitter feedline to index

- Made it so people.js also triggers upon clicking the person's image

- Added interns and some info to people.html

- Switched up the order of the logos in partners.html


-


Changes (30-08-24)

- Remade people.html and added a script "people.js" to it, also added a new image

- Added two extra cards to research.html

- Fixed a problem with accelerating.html (the cards weren't in the correct parents)

- Fixed two problems with partners.html (some images were missing and it didn't look good in mobile mode)


-


Changes (28-08-24)

- Changed partners.html (and removed the unnecessary css)

- Removed the php calls from contact.html


-


Changes (26-08-24)

- Added two new html docs: "partners.html" and "accelerating.html"

- Added a new images folder "assets/img/partners" containing the partners' logos

- Updated the navbar on all existing pages to accomodate the new docs

- Added a placeholder image in the assets/img/people folder

- Added the "Interns" block to people.html, also made some other minor changes to the page


-


Changes (28-07-24)

- Added a link at the end of prego.html to a new doc called "prego_demo.html"

- Added a new js file "webCamStart.js" to ask and allow access to the device's webcam and stream it to a video element in the page


-


Changes (24-07-24)

- Fixed a picture in people.html


-


Changes (17-07-24):

- Refactored code: the project docs are now in their own folder ("research.dir"), same for the failure and success pages (contact.dir) and the php scripts ("assets/php.dir") except for autoload.php, which is needed in the vendors folder

- Added the GitHub and arXiv links to the project docs

- Added pictures to people.html and renamed the third section from "Employees" to "Administration" (links, descriptions and the last image are still placeholders)

- Changed the send-email.php script so it reads the credentials and smtp info from a config.ini file in the root folder 

NOTE: Currently the file is called config.example.ini and contains examples, it needs the correct values AND to be renamed config.ini to actually work.
The proper config.ini should be kept on a local machine and never be pushed to GitHub.


-


Changes (14-07-24):

- Added two new docs dedicated to PREGO and HALO: "research_PREGO.html" and "research_HALO.html"

- Also added several images in the new projects/page_images folder and the new js script "halo.js"

- Added two "learn more" links in the research.html boxes to visit the new research docs

- Added the new php script "send-download.php" to contact.html to save the sent email as a text file

- Added an ajax script to contact.html to properly use both send-email.php and send-download.php


-


Changes (10-07-24):

- Added the 'name' and 'idea' fields to the contact.html form

- The contact.html form now works!
  It uses phpmailer (phpmailer, composer and autoload.php added to vendors folder, composer.json and composer.lock added to root)
  The script used to send the mail is called "send-email.php"
  Two new html docs: "sent-successfully.html" and "sent-unsuccessfully.html" added to show the result


-


Changes (07-07-24):

- Added the second and third blocks to people.html, added some placeholder people to the new blocks

- Added a contact list under each person in people.html (the placeholder links all lead to professor Galasso's pages)

- The contact page is now referred to as "Contact Us" in the navbars

- The contact form has been reimplemented in contact.html



-


Changes (04-07-24):

- Made the hamburger menu opaque while open

- Changed the boxes in research.html to light hrey

- Removed the wave svg from all pages expect for index.html

- Made the containers in people.html align items vertically while in mobile mode


-


Changes (30-06-24):

- Now the original navbar is shown in computer mode, and the hamburger menu appears in mobile mode

- Made the menu darker in mobile mode so the options are easier to see on a white background


-


Changes (25-06-24):

- Changed all docs' background to white (added two new svgs: "white_wave.svg" and "squished_white_wave.svg" to help)

- Changed the color of the boxes in research.html (and added a white box-shadow to the images)

- Moved the contact info from contact to index.html (contact is now empty)

- Changed the navbar into a very basic hamburger menu

- Fixed a problem with thin lines of the wrong color appearing at the bottom of svgs in mobile mode


-


Changes (22-06-24):

- Converted the "Squished_Wave" from png to svg and made minor changes to contact and reasearch.html docs

- Added a new svg "Squished_Wave_2" at the bottom of each doc

- Added a people.html doc and moved unimplemented content from indexOriginal to it (also updated navbar to accomodate it)


-


Changes (20-06-24):

- Moved all contact and research related code from index.html and moved it to new contact.html and research.html templates (also adjusted the navbar links accordingly)

- Changed padding classes in the new html docs

- Added a new css class ".hero-background-short" and "Squished_Wave.png" image to better fit new docs

- Added new favicon

- Kept original index and favicon files as "indexOriginal.html" and "faviconOriginal.ico"