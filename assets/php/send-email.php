<?php
$name = filter_var($_POST["name"], FILTER_SANITIZE_FULL_SPECIAL_CHARS);
$email = filter_var($_POST["email"], FILTER_SANITIZE_FULL_SPECIAL_CHARS);
$subject = "Contact Us Submission"; # Swap the string with '$_POST["subject"];' if a subject field is ever added
$idea = filter_var($_POST["idea"], FILTER_SANITIZE_FULL_SPECIAL_CHARS);

# Reqs
require "../../vendors/autoload.php";

use PHPMailer\PHPMailer\Exception;
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;

$config_ini = parse_ini_file("../../config.ini");

# Setup
$mail = new PHPMailer(true);

$mail->isSMTP();
$mail->SMTPAuth = true;

$mail->Host = $config_ini["smtp_host"];
$mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
$mail->Port = $config_ini["smtp_port"];

$mail->Username = $config_ini["smtp_username"];
$mail->Password = $config_ini["smtp_password"];

$mail->setFrom($config_ini["domain_address"], 'Idea ItalAI di '.$name ); # Sender
$mail->addAddress($config_ini["recipient_address"], $config_ini["recipient_name"]); # Recipient
$mail->Subject = $subject;

# Body
$mail->isHTML(true);
$mail->Body = '<div>Nome: '.$name.'<br>Email: '.$email.'<br><br>Messaggio:<br>'.$idea.'</div>';

if(empty($name) || empty($email) || empty($idea) || !$mail->send()) {header("HTTP/1.1 400 Bad Request");}
else {header("HTTP/1.1 200 OK");}
?>