# azure-hugo

azure-hugo helps you deploy your [Hugo][]-powered static site to [Azure][] with just a few steps.

[Hugo]: https://gohugo.io
[Azure]: https://docs.microsoft.com/en-us/azure/app-service/app-service-web-overview

Once set up, you can:

* Store your site in a Git repository on GitHub
* Deploy directly from your Git repository -- no need to build your site locally first
* Add posts for future publication and they'll be published automatically
* Build your site incrementally on a schedule
* Upgrade the version of Hugo used to build your site just by pushing a Git commit

## Pre-reqs and assumptions

The instructions here assume that you are reasonably familiar with Azure App Service and deploying sites to it. They assume you know how to configure your site to be deployed from a Git repository on GitHub, and that you have that set up for your Hugo site. These instructions will guide you in configuring your repo to build automatically when deployed to Azure.

## Add this repository to your site's Git repo as a submodule

You can do that using the following command in the root of your site's Git repository:

`git submodule add -b master https://github.com/tylerbutler/azure-hugo.git`

That will create a top-level azure-hugo subdirectory and check out the contents of this repository. If you've used Hugo for a while, then this will seem familiar, because it's the way most Hugo themes are distributed -- as Git submodules.

Commit the results using a command like `git commit -m "Add azure-hugo"`. Congratulations! You now have access to the PowerShell functions included in this repository, namely the `Install-Hugo` and `Invoke-SiteBuild` functions which we'll now use to build your site during deployment and periodically.

## Configure your site to build on deployment

At this point you have a few options. We'll walk through the simplest one here, but if you have already [customized your deployment](https://github.com/projectkudu/kudu/wiki/Customizing-deployments) or would prefer to configure deployment via the Azure portal instead of using a `.deployment` file like we do here, rest assured that you can do it. You'll just need to adjust these steps for your situation. Pull requests that add more info to this readme are welcome, of course!

The aforementioned simplest option is this:

Copy the `.deployment` file from this repository to the root of your site's Git repo. Assuming you're at the root of your repo, you might use a command like this:

`copy .\azure-hugo\.deployment .deployment`

The `.deployment` file is used by Azure to determine what command to run when performing a Git deployment. In our case, we've just configured Azure to execute the `deploy.ps1` PowerShell script in this repository. That script in turn installs Hugo if it isn't already installed and runs a local build.

For more explanation of the crazy syntax of the 'run deploy.ps1 please' command in `.deployment` see https://github.com/projectkudu/kudu/wiki/Customizing-deployments#deploying-with-custom-script

And that's it! You should now be able to deploy your site by committing to Git locally and pushing to GitHub. Azure will execute the `azure-hugo\deploy.ps1` script when your site is deployed, which will in turn run a Hugo build, outputting the results to Azure's site root.

If that's all you want, you can skip the next section. Otherwise read on to configure your site to build on a schedule.

## Scheduled site builds

One limitation of static sites is that you can't easily schedule something to be published in the future. Or, more precisely, you *can* do it but you need to build your site after the publish date in order for it to go live. In Hugo you do this by setting the `publishDate` [front matter property](https://gohugo.io/content-management/front-matter/) to some time in the future, and by default the content will be ignored during build unless the current time is past the `publishDate`.

Clearly this limits the usefulness of 'future publication' in static sites. Unless, of course, we can build our site periodically. And it turns out we can, using an Azure feature called [WebJobs](https://docs.microsoft.com/en-us/Azure/app-service/web-sites-create-web-jobs).

The Azure docs focus on how to use the Azure Portal UI to configure this, but it turns out you can also simply deploy a script and a settings file to a specific location in your site and Azure will run them. I think that's a lot better because it means that the WebJob can be versioned in Git along with your site.

In order for Azure to see your WebJob, its files need to wind up in `app_data\jobs\triggered\NAME_OF_YOUR_JOB\`. Since we're using Hugo, we need to place the files under the `static` folder (assuming you're using the Hugo defaults; if you have a different folder for your static content then use it instead).

This repository includes a WebJob that executes a build every two hours. You can manually copy it to the appropriate location in your site, or use this Robocopy command from the root of your site's repository:

`Robocopy.exe .\azure-hugo\static\ .\static\ /e`

You now have a WebJob called hugo_build that will run every two hours!

### Change the build schedule

If you want to change how often your site is built, you can adjust the `schedule` property in the WebJob's `settings.job` file. The WebJob included with this repository uses a value of `0 0 */2 * * *` by default, or every two hours. Refer to [CRON expressions](https://docs.microsoft.com/en-us/Azure/azure-functions/functions-bindings-timer#cron-expressions) for more information and examples of schedules that you can set. CRON is surprisingly expressive.

## Upgrading Hugo

You shouldn't really need to do anything to maintain this system once it is configured. However, Hugo releases new versions regularly, and sooner or later you're going to want to upgrade.

When that happens, your first step should be to update the azure-hugo submodule in your site's repository, because this repository may have already been updated to use the new version. The current version used is:

-----

_Current Hugo Version: **0.54**_

-----

Assuming this repository has been updated, then you can just update the submodule using this command, then commit and push the results:

`git submodule update --remote`

If the repository has not yet been updated, please file an issue or open a pull request.

## Known issues and potential improvements

### Automated cleanup of old Hugo versions

There's no cleanup of old Hugo versions, but it seems like a good idea. Over time a lot of exes will build up.

### Build command customization

This seems like it would be useful, but right now you're stuck with the simple build command I use.

### Better Hugo version management

Shouldn't I be able to upgrade Hugo independently from updating this submodule? Maybe use an environment variable for the version with a default if the variable's not set?
