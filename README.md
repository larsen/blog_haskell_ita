# blog.haskell-ita.it

## How to Update the Website

### Initial Setup

Clone this repo locally.

Compile the application with Nix or Stack. 

#### Nix Instructions

Execute

    ./generate-nix-project.sh
    nix-shell ./shell.nix
    cabal build
    ./dist/build/site/site clean
    ./dist/build/site/site build

#### Stack Instructions

TODO complete

### Website Configuration

The file `site.hs` contains the rules used from Hakyll for generating the website. Every time you change them:

* recomplie the application
* clean the website with `site clean`

### Website Preview

Execute

    site watch

for a live preview of the website. In case of change of files, the preview is updated.

### Adding a Post

Add posts inside `posts/` directory, in the proper subdirector, playing the role of category.

Use already defined posts as example. Hakyll uses Pandoc that is very powerful and many different type of files are accepted.

#### Teaser

It is convenient to have an excerpt of a post displayed on the index page along with a “Read more…” link to encourage your readers to read the rest of the post. For doing this put the teaser symbol where the excerpt end. 

    <!--more-->

In case of Literate Haskell Code use instead

    <div></div><!--more-->

for bypassing the byrding style `>` character.

#### Images

Use something like

    <img src="/images/photos/meetup_2015_estate.jpg" alt="photo" class="img-thumbnail">

on the first column of a Markdown file. Pandoc will insert directly the HTML code. The class is used from Bootstrap CSS template for scaling and decorating the image.

#### Change Top Menu

Change the function `renderTagListForTopMenu` inside `site.hs` 

#### Change Page Format

Change all files in templates directory. Same format is repeated for:

* blog-list
* blog post
* page

#### Change "About" Page

Change `about.md` file.

### Website Update

Execute

    site build

for updating the `_site/` directory. In case of big changes it is better a

    site clean
    site build

Then make a Git commit, and push to the remote repo.

    git status
    git add <missing-files>
    git commit -a -m "<some-message>"
    git push

The hosting server will make a pull, and publish the content of `_site/` directory. All other content will be not be published. 

### Known Problems

If you miss the tag `date`, Hakyll generates a not clear error message like:

     [ERROR] Missing field $posts$ in context for item 3/index.html

## Project Roadmap (TODO)

### Initial Release

TODO ripetere i link ai contatti sia nel footer che nella pagina about

TODO mettere i CONTACTS con tutti gli altri siti che formano la community

TODO pensare se mettere in alto la dicitura Haskell-ITA

TODO usare una retinatura nella NAV-BAR in alto

TODO togliere gap top iniziale

TODO fare delle file eleganti di bottoni nel footer

TODO rendere fisso il menu in alto

TODO migliorare impaginazione testo:
* colori
* interlinea
* dimensioni corpo
* colore link

TODO vedere anche il bottone MORE che compare in fondo alle pagine

TODO non carica piu\` alcuni fonts, e si blocca nel caricamento, vedere il motivo

TODO usare un font migliore per il LOGO

TODO ridurre spazio nel header sopra dedicato al titolo, basta molto più piccolo

TODO vedere se il browser segnala degli errori

TODO essere sicuri di usare il nero per il blog

TODO i sottotitoli nei blog devono avere dimensioni minori dei titoli del blog

TODO aggiungere siti in basso social appropiati e anche altri indicatori

TODO aggiungere in basso che e\` stato costrito con Hakyll

TODO includere link al repository con il sito

TODO il titolo del blog deve essere un link

TODO sistemare paginazione in basso

TODO test haskell-ita piccolo

TODO aggiungere logo

TODO nel footer descrivere chi siamo

TODO provare a fare subscribe ai FEEDS quando ho installato 

TODO chiedere se puo` diventare la pagina standard di Haskell invece che il blog

TODO aggiungere DISQUS o simile ai post

## Automatic Update of the WebSite

TODO create a web-hook on GitHub

TODO the web server receive the hook, make git pull of the repo, and then make a site build

TODO daily the web server execute also a site clean and regeneration, in order to manage the big changes in the structure of the code of the site

