<?php
$name = filter_var($_POST["name"], FILTER_SANITIZE_FULL_SPECIAL_CHARS);
$email = filter_var($_POST["email"], FILTER_SANITIZE_FULL_SPECIAL_CHARS);
$subject = "Contact Us Submission"; # Swap the string with '$_POST["subject"];' if a subject field is ever added
$idea = filter_var($_POST["idea"], FILTER_SANITIZE_FULL_SPECIAL_CHARS);

require "../../vendors/autoload.php";

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;

$mail = new PHPMailer(true);

$mail->isSMTP();
$mail->SMTPAuth = true;

$mail->Host = "sandbox.smtp.mailtrap.io"; # example
$mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
$mail->Port = 587; # example

$mail->Username = "72522bd3252397"; # example
$mail->Password = "432b075ec68871"; # example

$mail->setFrom($email, $name);
$mail->addAddress("federico.capa01@gmail.com", "Fede"); # recipient example

$mail->Subject = $subject;
$mail->Body = $idea;

$mail->preSend();
$sRawEML = $mail->getSentMIMEMessage();
$timestamp = date('m-d-Y_hia');

$myfilename="italai-submission_".$timestamp.'.txt';
$dataForFile="ItalAI Submission ";
$dataForFile.=$timestamp;
$dataForFile.="\nName: ";
$dataForFile.=$name;
$dataForFile.="\nEmail: ";
$dataForFile.=$email;
$dataForFile.="\n\nIdea: \n";
$dataForFile.=$idea;
nl2br($dataForFile);

header('Content-type: application/x-download');
header('Content-Disposition: attachment; filename="'.$myfilename.'"');
header('Content-Transfer-Encoding: binary');
header('Content-Length: '.strlen($dataForFile));
set_time_limit(0);
echo $dataForFile;
exit;
?>