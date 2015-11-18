{-# LANGUAGE OverloadedStrings, TupleSections #-}

-- Initial Author: Massimo Zaniboni <massimo.zaniboni@docmelody.com>
-- Code partially based on https://github.com/gislik/gisli.hamstur.is 

import            Data.Monoid (mappend)
import            Data.Typeable                    (Typeable)
import            Data.Binary                      (Binary)
import            Data.Maybe                       (fromMaybe, listToMaybe)
import            Data.Monoid                      ((<>), mconcat)
import            Data.Functor                     ((<$>))
import            Data.List                        (intercalate, intersperse, unfoldr, sortBy, isSuffixOf)
import            Data.Char                        (toLower, toUpper)
import            Data.Time.Clock                  (UTCTime (..))
import            Control.Monad                    (msum, filterM, (<=<), liftM, forM, filterM)
import            System.Environment               (getArgs)
import            Data.Time.Format                 (TimeLocale, defaultTimeLocale, parseTimeM, formatTime)
import            Text.Printf                      (printf)
import            Text.Blaze.Html                  (toHtml, toValue, (!))
import            Text.Blaze.Html.Renderer.String  (renderHtml)
import qualified  Data.Set                         as S
import qualified  Data.Map                         as M
import qualified  Text.Blaze.Html5                 as H
import qualified  Text.Blaze.Html5.Attributes      as A
import            System.FilePath                  
import            Hakyll

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do

    tags <- buildTags blogPattern (fromCapture "*/index.html")
    pages <- buildPages Nothing blogPattern

    match "favicon.ico" $ do
        route   idRoute
        compile copyFileCompiler

    -- static content
    match "*.css" $ do
        route   idRoute
        compile compressCssCompiler

    match ("*.png" .||. "*.txt" .||. "assets/**") $ do
         route   idRoute
         compile copyFileCompiler

    -- blogs
    match blogPattern $ do
         route blogRoute
         compile $ pandocCompiler
            >>= saveSnapshot blogSnapshot
            >>= loadAndApplyTemplate "templates/blog.html"    (blogDetailCtx tags)
            >>= loadAndApplyTemplate "templates/default.html" defaultContext

    -- index
    match "index.html" $ do
         route idRoute
         compile $ do
            getResourceBody
               >>= applyAsTemplate (pageCtx 1 pages tags)
               >>= loadAndApplyTemplate "templates/default.html" indexCtx 

    -- pages
    paginateRules pages $ \i _ -> do
         route idRoute
         compile $ makeItem (show i)
            >>= loadAndApplyTemplate "templates/blog-list.html" (pageCtx i pages tags)
            >>= loadAndApplyTemplate "templates/default.html" defaultContext

    -- category index
    tagsRules tags $ \category pattern -> do
         catPages <- buildPages (Just category) pattern
         route idRoute
         compile $ do
            makeItem category
               >>= loadAndApplyTemplate "templates/blog-list.html" (pageCtx 1 pages tags)
               >>= loadAndApplyTemplate "templates/default.html" indexCtx

         -- category pages
         paginateRules catPages $ \i _ -> do
            route idRoute
            compile $ do
               makeItem category
                  >>= loadAndApplyTemplate "templates/blog-list.html" (pageCtx i catPages tags)
                  >>= loadAndApplyTemplate "templates/default.html" defaultContext

    -- TODO add front-page section into rss
    
    -- rss
    create ["rss/index.html"] $ do
         route idRoute
         compile $ renderBlogRss <=< fmap (take 20) . loadBlogs $ blogPattern

    -- templates
    match "templates/*.html" $ compile templateCompiler

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------

-- | The setting used for generating posts.
postCtx :: Context String
postCtx =
    dateField "date" "%Y-%m-%d" `mappend`
    defaultContext

-- | The settings used for generating Atom Feeds.
myFeedConfiguration :: FeedConfiguration
myFeedConfiguration = FeedConfiguration
    { feedTitle       = "Haskell-ITA"
    , feedDescription = "The Italian Community of Haskell Programmers"
    , feedAuthorName  = "Haskell-ITA"
    , feedAuthorEmail = "info@haskell-ita.it"
    , feedRoot        = "http://www.haskell-ita.it"
    }

frontPagePattern :: Pattern
frontPagePattern = "frontpage/**"

blogPattern :: Pattern
blogPattern = "posts/**"

blogSnapshot :: Snapshot
blogSnapshot = "blog-content"

blogPerPage :: Int
blogPerPage = 4

blogOrder :: (MonadMetadata m, Functor m) => [Item a] -> m [Item a]
blogOrder = recentFirst

--------------------------------------------------------------------------------
-- CONTEXTS
--------------------------------------------------------------------------------

indexCtx :: Context String
indexCtx = 
   prettyTitleField "title" <> 
   bodyField        "body"  <>
   metadataField            <>
   urlField         "url"   <>
   pathField        "path"  <>
   missingField

pageCtx :: PageNumber -> Paginate -> Tags -> Context String
pageCtx i pages tags = 
      blogListField "posts" (loadBlogs pattern)      <>
      field "tags" (const . renderTagList' $ tags)              <>
      constField "title" "Pagination"                           <>
      paginateContext' pages i                                  <>
      defaultContext
  where
      pattern = fromList . fromMaybe [] . M.lookup i . paginateMap $ pages
      paginateContext' pages i = mapContextP (isSuffixOf "Url") dropFileName (paginateContext pages i)
      blogListField name loader = listField name (blogDetailCtx tags) loader

blogDetailCtx :: Tags -> Context String
blogDetailCtx tags = 
      dateField "date" "%B %e, %Y"              <>
      mapContext dropFileName (urlField "url")  <>
      teaserField "teaser" blogSnapshot         <>
      defaultContext
  
rssCtx :: Context String
rssCtx = 
      cdataContext metadataField    <>
      bodyField "description"       <>
      urlField "url"                <>
      defaultContext
   where
      cdataContext = mapContext (\s -> "<![CDATA[" <> s <> "]]>")

--------------------------------------------------------------------------------
-- ROUTES
--------------------------------------------------------------------------------

blogRoute :: Routes
blogRoute = 
      customRoute (takeFileName . toFilePath)     `composeRoutes`
      metadataRoute dateRoute                     `composeRoutes` 
      dropDateRoute                               `composeRoutes` 
      pageRoute
   where 
      dateRoute metadata = customRoute $ \id' -> joinPath [dateFolder id' metadata, toFilePath id']
      dateFolder id' = maybe mempty (formatTime defaultTimeLocale "%Y/%m") . tryParseDate id'
      dropDateRoute = gsubRoute "[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}-" (const mempty)

-- TODO capire cosa fa questo!!

pageRoute :: Routes
pageRoute = removeExtension `composeRoutes` addIndex
   where 
      removeExtension       = setExtension mempty
      addIndex              = postfixRoute "index.html"
      postfixRoute postfix  = customRoute $ (</> postfix) . toFilePath

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------
-- contexts
mapContextP :: (String -> Bool) -> (String -> String) -> Context a -> Context a
mapContextP p f c'@(Context c) = Context $ \k a i -> 
                      if p k 
                        then unContext (mapContext f c') k a i 
                        else c k a i

prettyTitleField :: String -> Context a
prettyTitleField = mapContext (defaultTitle . pageTitle) . pathField 
   where
      pageTitle :: String -> String
      pageTitle = intercalate " &#x276f;&#x276f;= " . splitDirectories . capitalize . dropFileName

      defaultTitle :: String -> String
      defaultTitle "." = "Blog"
      defaultTitle x = x

      capitalize :: String -> String
      capitalize [] = []
      capitalize (x:xs) = toUpper x : map toLower xs

categoryField' :: String -> Tags -> Context a -- drops the filename from the link
categoryField' = tagsFieldWith getCategory simpleRenderLink (mconcat . intersperse ", ")
   where
      getCategory :: Identifier -> Compiler [String]
      getCategory = return . return . takeBaseName . takeDirectory . toFilePath

-- compilers
loadBlogs :: (Typeable a, Binary a) => Pattern -> Compiler [Item a]
loadBlogs = blogOrder <=< flip loadAllSnapshots blogSnapshot

buildPages :: (MonadMetadata m, Functor m) => Maybe String -> Pattern -> m Paginate
buildPages mprefix pattern = 
   buildPaginateWith 
      (return . paginateEvery blogPerPage)
      pattern
      (asIdentifier mprefix . show)
   where
      asIdentifier :: Maybe String -> String -> Identifier
      asIdentifier Nothing    = fromCapture "*/index.html" 
      asIdentifier (Just pre) = fromCapture . fromGlob $ pre <> "/*/index.html" 

renderTagList' :: Tags -> Compiler String -- drops the filename from the link
renderTagList' = renderTags makeLink (intercalate " ")
   where
      makeLink tag url count _ _ = renderHtml $
         H.a ! A.href (toValue . dropFileName $ url) $ toHtml (tag ++ " (" ++ show count ++ ")")

renderBlogRss :: [Item String] -> Compiler (Item String)
renderBlogRss = renderRss myFeedConfiguration rssCtx

-- metadata
includeTagM :: MonadMetadata m => String -> [Identifier] -> m [Identifier]
includeTagM tag = filterTagsM (return . elem tag)

filterTagsM :: MonadMetadata m => ([String] -> m Bool) -> [Identifier] -> m [Identifier]
filterTagsM p = filterM $ p <=< getTags 

-- html
simpleRenderLink :: String -> (Maybe FilePath) -> Maybe H.Html
simpleRenderLink _   Nothing         = Nothing
simpleRenderLink tag (Just filePath) =
  Just $ H.a ! A.href (toValue $ toUrl . dropFileName $ filePath) $ toHtml tag

-- dates
tryParseDate :: Identifier -> Metadata -> Maybe UTCTime
tryParseDate = tryParseDateWithLocale defaultTimeLocale

-- TODO switch to ISO locale

tryParseDateWithLocale :: TimeLocale -> Identifier -> Metadata -> Maybe UTCTime
tryParseDateWithLocale locale id' metadata = do
   let tryField k fmt = M.lookup k metadata >>= parseTime' fmt
       fn             = takeFileName $ toFilePath id'

   maybe empty' return $ msum $
      [tryField "published" fmt | fmt <- formats] ++
      [tryField "date"      fmt | fmt <- formats] ++
      [parseTime' "%Y-%m-%d" $ intercalate "-" $ take 3 $ splitAll "-" fn]
   where
      empty'     = fail $ "Hakyll.Web.Template.Context.getItemUTC: " 
                        ++ "could not parse time for " ++ show id'
      parseTime' = parseTimeM True locale 
      formats    =
         [ "%a, %d %b %Y %H:%M:%S %Z"
         , "%Y-%m-%dT%H:%M:%S%Z"
         , "%Y-%m-%d %H:%M:%S%Z"
         , "%Y-%m-%d"
         , "%B %e, %Y %l:%M %p"
         , "%B %e, %Y"
         ]
