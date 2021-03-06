xquery version "3.1";

(:~
 : This post-install script sets permissions on the package data collection hierarchy.
 : When pre-install creates the public-repo-data collection, its permissions are admin/dba. 
 : This ensures the collections are owned by the default user and group for the app.
 : The script also builds the package metadata if it doesn't already exist.
 :)
 
import module namespace config="http://exist-db.org/xquery/apps/config" at "modules/config.xqm";
import module namespace scanrepo="http://exist-db.org/xquery/admin/scanrepo" at "modules/scan.xqm";

declare namespace sm="http://exist-db.org/xquery/securitymanager";
declare namespace system="http://exist-db.org/xquery/system";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

(: Until https://github.com/eXist-db/exist/issues/3734 is fixed, we hard code the default group name :)
declare variable $repo-group := 
    (: config:repo-permissions()?group :)
    "repo"
;
declare variable $repo-user := 
    (: config:repo-permissions()?user :)
    "repo"
;

(:~
 : Set user and group to be owner by values in repo.xml
 :)
declare function local:set-data-collection-permissions($resource as xs:string) {
    if (sm:get-permissions(xs:anyURI($resource))/sm:permission/@group = $repo-group) then
        ()
    else
        (
            sm:chown($resource, $repo-user),
            sm:chgrp($resource, $repo-group),
            sm:chmod(xs:anyURI($resource), "rwxrwxr-x")
        )
};

(: Set user and group ownership on the package data collection hierarchy :)

for $col in ($config:app-data-col, xmldb:get-child-collections($config:app-data-col) ! ($config:app-data-col || "/" || .))
return
    local:set-data-collection-permissions($col),

(: Build package metadata if missing :)

if (doc-available($config:raw-packages-doc) and doc-available($config:package-groups-doc)) then
    ()
else
    (
        scanrepo:rebuild-all-package-metadata(),
        ($config:raw-packages-doc, $config:package-groups-doc) ! local:set-data-collection-permissions(.)
    ),
    
(: execute get-package.xq as repo group, so that it can write to logs :)
sm:chmod(xs:anyURI($target || "/modules/get-package.xq"), "rwsrwxr-x")