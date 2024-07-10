<?php

$name = filter_var($_POST["name"], FILTER_SANITIZE_FULL_SPECIAL_CHARS);
$email = filter_var($_POST["email"], FILTER_SANITIZE_FULL_SPECIAL_CHARS);
$subject = "Contact Us Submission"; # Swap the string with '$_POST["subject"];' if a subject field is ever added
$idea = filter_var($_POST["idea"], FILTER_SANITIZE_FULL_SPECIAL_CHARS);

require "vendors/autoload.php";

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;

$mail = new PHPMailer(true);

$mail->isSMTP();
$mail->SMTPAuth = true;

$mail->Host = "something.smtp.mailexample.io"; # example
$mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
$mail->Port = 123; # example

$mail->Username = "123123abcabc"; # example
$mail->Password = "456456defdef"; # example

$mail->setFrom($email, $name);
$mail->addAddress("company.email.com", "someone"); # recipient example before prod

$mail->Subject = $subject;
$mail->Body = $idea;

if(empty($name) || empty($email) || empty($idea) || !$mail->send()) {header("Location: sent-unsuccessfully.html");}
else {header("Location: sent-successfully.html");}

?>