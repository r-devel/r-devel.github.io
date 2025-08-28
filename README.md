# Source for [R Contributor Site](https://contributor.r-project.org/)

The website is built with [Quarto](https://quarto.org)

## Website structure

The top-level pages linked in the menu are in correspondingly named .qmd files, e.g. 

| Menu item   | Markdown file | Relative URL |
|-------------|---------------|--------------|
| Home        | `index.qmd`    | `/`          |
| Slack Group | `slack.qmd`    | `/slack`     |

You can create sub-pages by creating a folder with an `index.qmd` file. 
Any further markdown pages within that folder will be sub-pages under that, e.g.

| Markdown file | Relative URL |
|---------------|---------------|
|`translating-r-to-your-language/index.qmd` | `/translating-r-to-your-language` |  
|`translating-r-to-your-language/prep.qmd` | `/translating-r-to-your-language/prep` |
  
## Basic editing

You can edit the .qmd files on the `main` branch and the changes will be automatically deployed to the live site once the changes are committed. If you edit the files directly on GitHub using the browser editor, then you can use the Preview tab to check the formatting before committing.

## Substantial editing

If you are making substantial changes, e.g. adding a new page, or making changes that require collaborating editing/review before being pushed, create a branch and make the changes there.

Any changes pushed to a different branch will not be automatically deployed to preview, so if the GitHub editor preview is not sufficient (i.e. you are doing more than editing a single page) it is best to clone the repo and make your changes locally.

### Previewing locally

To preview the site locally, you will need to install Quarto, see https://quarto.org/docs/get-started/.

To build the site and make it available on a local server, run the following command in a terminal from the top level directory of the locally cloned repository:

```
quarto preview
```

### Creating pages

Please use the following YAML fields when creating new pages:

    ---
    title: The title
    description: Short description, less than 160 characters.
    image: your-image.png
    ---
 
The description is used to create cards when sharing links on social media but will not appear on the page itself.

If you don't specify an image in the YAML, an the first image on the page will be used as the image for social media cards (including alternative text).
The image file should be in the same directory as the .qmd file.
JPG, PNG, WEBP and GIF formats are supported (only the first frame of an animated GIF will be used).

You can check how the card will look using the following validators:

 - https://cards-dev.twitter.com/validator
 - https://developers.facebook.com/tools/debug/ 
 
The Facebook debugger requires log in; you can ignore the following warning

    The following required properties are missing: fb:app_id
    
as that property is not required.

### Editing the menu

To edit the menu you need to edit the `navbar` field of `_quarto.yml`.

To add a new page, add a new element with the title and URL of the page. Use the relative URL for pages in this repo, e.g.

```
  - text: Slack Group
    file: slack.qmd
```

Use the full URL for external pages, e.g. 

```
  - text: R Developer Page
    href: https://developer.r-project.org/
```  

## Website theme

This is a GitHub pages site, using the R Contributor [brand.yml](https://posit-dev.github.io/brand-yml/) files: `brand-light.yml` and `brand-dark.yml` for light and dark mode respectively. 

