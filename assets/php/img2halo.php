<?php
$path = $_POST['path'];

$paths = array();
$paths[] = substr($path,3);
$paths[] = substr($path,3);
$paths[] = substr($path,3);

echo json_encode($paths);
?>