xquery version "3.1";

(:~
 : Receives uploaded packages and immediately publishes them to the package repository
 :)

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace scanrepo="http://exist-db.org/xquery/admin/scanrepo" at "scan.xqm";

declare namespace request="http://exist-db.org/xquery/request";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

declare function local:upload-and-publish($xar-filename as xs:string, $xar-binary as xs:base64Binary) {
    let $path := xmldb:store($config:packages-col, $xar-filename, $xar-binary)
    let $publish := scanrepo:publish-package($xar-filename)
    return
        map { 
            "files": array {
                map { 
                    "name": $xar-filename,
                    "type": xmldb:get-mime-type($path),
                    "size": xmldb:size($config:packages-col, $xar-filename)
                }   
            }
        }
};

let $xar-filename := request:get-uploaded-file-name("files[]")
let $xar-binary := request:get-uploaded-file-data("files[]")
return
    try {
        local:upload-and-publish($xar-filename, $xar-binary)
    } catch * {
        map {
            "result": 
                map { 
                    "name": $xar-filename,
                    "error": $err:description
                }
        }
    }
