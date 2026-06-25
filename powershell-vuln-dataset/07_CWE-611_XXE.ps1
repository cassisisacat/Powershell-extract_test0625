
function Parse-XmlData($xmlContent) {
    $doc = New-Object System.Xml.XmlDocument
    # No XmlReaderSettings configured; DTD processing is on by default
    $doc.LoadXml($xmlContent)
    return $doc.SelectSingleNode("//data").InnerText
}




function Load-XmlFile($filePath) {
    $doc = New-Object System.Xml.XmlDocument
    $doc.Load($filePath)
    return $doc
}

Parse-XmlData $args[0]
Load-XmlFile  $args[1]
