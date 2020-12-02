
First - quick Getting Started for Development! (more about BraceApp below...)

First you have to have already setup the brace language environment, see
https://gitlab.com/edgii/brace (Getting Started in Readme.md) for that

then, from the directory containing "brace" (where you cloned it), clone braceApp
(from your shell / on MSWin from the git shell you installed)

git clone https://gitlab.com/edgii/braceApp
cd braceApp
./scripts/devprep.sh

that's it - Brace as such is just a source and dependencies library project
to actually use it checkout and build a project that uses it (here's a couple):

https://gitlab.com/edgii/BNote
https://gitlab.com/edgii/BBridge

End of Getting Started for Development!

The Brace application infrastructure is a framework written in the [Brace](https://gitlab.com/edgii/brace) programming language licensed under the [BSD-3-Clause](https://opensource.org/licenses/BSD-3-Clause) open source license which enables the authoring of web and hybrid applications that target a wide range of environments - Linux, Windows, or Mac desktop applications using the built-in browser, Android and IOS mobile applications using the built-in webviews, and a hosted application as a website.  Includes web user interface infrastructure and key/value database support, web service / http(s) client support, as well as cross platform support for io, file, and process management.  See the [Bitsii](https://gitlab.com/edgii/Bitsii/-/wikis/home) project for some examples.
