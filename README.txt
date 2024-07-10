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