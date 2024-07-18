<?php
$img = $_FILES["img2halo"];
$temp = "../../temp/";
$path = $temp . basename($img["name"]);
$ext = strtolower(pathinfo($path,PATHINFO_EXTENSION));

// Double check for jpg and png
if($ext != "jpg" && $ext != "png") {
  header("HTTP/1.1 202 Accepted");
  echo "File Not Valid";
  exit;
}

// Max 500kb
if ($img["size"] > 500000) {
  header("HTTP/1.1 202 Accepted");
  echo "Max File Size: 500kb";
  exit;
}

// Try to upload
if (move_uploaded_file($img["tmp_name"], $path)) {
  header("HTTP/1.1 200 OK");
  echo $path;
  exit;
}
else {
  header("HTTP/1.1 202 Accepted");
  echo "An unexpected error has occured... Please try again later";}
  exit;
?>