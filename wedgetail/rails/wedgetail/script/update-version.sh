#!/bin/sh
sed -i "s/^r.*/r`svnversion`/" app/views/layouts/_side_links.rhtml
