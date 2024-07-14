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

$mail->Host = "something.smtp.somethang.example"; # example
$mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
$mail->Port = 123; # example

$mail->Username = "123123abcabc"; # example
$mail->Password = "123123abcabc"; # example

$mail->setFrom($email, $name);
$mail->addAddress("company_email@gmail.com", "some_name"); # recipient example

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