# Migration Data Explorer - Public

This is the public version of the Migration Data Explorer, developed
for Migration, Evidence & Insights, Ministry of Business, Innovation
and Employment (MBIE).

The material in this repository is provided "as is", without warranty
of any kind, express or implied.

You are welcome to fork and make changes as you wish, subject to the
conditions of the licence below, but note that it is unlikely any
issues (or pull requests) raised will be answered.

All copyright material is protected by copyright owned by the Ministry
of Business, Innovation and Employment on behalf of the Crown.

Crown Copyright &copy;.

Unless indicated otherwise for specific items or collections of
content (either below or within specific items or collections), this
copyright material is licensed for re-use under a Creative Commons
Attribution 4.0 International Licence.

In essence, you are free to copy, distribute and adapt the material,
as long as you attribute it to the Ministry of Business, Innovation
and Employment (MBIE) and abide by the other terms of the licence.

Please note that this licence does not apply to any logos, emblems and
trade marks or to any photography and imagery included in the
repository. Those specific items may not be re-used without express
permission.

The permission to reproduce material in this repository does not
extend to any material that is identified as being protected by
copyright owned by a third party. (This includes material on websites
you may access via links in the repository).

We cannot grant permission to reproduce such material: you must obtain
permission directly from the copyright owner(s).

## Differences from Internal Repository

The public version is different from the version held internally at
MBIE in a few ways:

1. Data preparation steps have been removed, as they will not work
   outside the MBIE network.
2. The on-the-fly random rounding scripts have been removed and
   instead the data is provided pre-rounded. This means the values
   from this version will have greater cumulative rounding errors than
   the version provided by MBIE (which applies rounding at the final
   step and thus does not introduce any additional errors).
3. Google Analytics has been disabled and replaced with a dummy.
4. The public version includes the scripts which are used to produce
   the public repo variation from the internal repo.
5. The public version repo is a wholly separate repo, and does not
   share the commit history of the internal repo.

Over time, the public version may also drift as updates to either
version is not promptly mirrored in the other.

# Background

Originally intended as a release and dissemination mechanism to go
with *a new conceptual framework for analysing migration trends based
on determining migration's impact on the population and labour supply,
which moves away from existing administrative metrics such as visa
approval numbers*, life for this tool began with a tab aptly named
`ProtoTab` to accomplish this goal. The `ProtoTab` contained only a
single dataset, which would eventually become the `Population` dataset
when the Data Explorer was eventually released.

When concerns were raised about the data released on the Immigration
New Zealand website as CSV files, this tool was picked as the ideal
platform to release that data more appropriately, by featuring
improved selection methods and on-the-fly random rounding to protect
privacy. Thus the `BetterCSVs` tab was born.

This meant the Data Explorer now had two quite different interfaces,
born with two vastly different goals in mind. It made sense to have a
single consistent interface, and after conducting some user tests it
was decided that the `ProtoTab` would be removed and merged into the
`BetterCSVs` tab, which would handle the new `Population` and `Visa
Flows` datasets, in addition to the Immigration New Zealand CSV files
it was originally designed to handle. Thus the `BetterCSVs` tab became
the sole tab for the tool and relabelled to the *Data Explorer* tab.

However the current phase of development has drawn to a close, and due
to time constraints the repository is left with vestiges of unused
code and out-of-date documentation, for which the author apologises in
advance.

# Structure

The core functionality is defined in the files `helper_funcs.R` and
`helper_funcs.js`. The R file mostly handles the server-side
functionality, but also sets up many of the ui elements. The
JavaScript file enhances the client-side experience by running
directly on the client browser, eliminating the lag associated with
communicating with the server (a common shortcoming of pure Shiny
Apps).

For legacy reasons, the code is structured under the assumption that
there are multiple tabs, each with tab-specific helper functions, that
draw upon a collection of global helper functions. However, as the
Migration Data Explorer has only one real functional tab (the Data
Explorer tab) this separation unfortunately adds unnecessary
confusion. A code re-factor would have resolved this issue, but as
noted above this was not carried out due to various constraints.

In addition to the core functionality provided by the `helper_funcs`
files, there are a number of other helper functions that have been
made more modular and spun out into individual files.

# Making changes

## Changing the non-functional tabs

The file `ui_doctabs.R` defines much of the text for the tool,
including the contents of the non-function tabs, like the initial
landing page (called `frontp`) and the help page (called `helpp`).

This is largely defined using the shiny/htmltools syntax for
constructing HTML elements.

## Changing the dataset definitions (descriptors)

The dataset definitions (e.g. the descriptions in the tooltips that
come up when the user hovers their mouse over a Dataset, or a
Variable) are defined in `json` files inside the `www` sub-directory,
e.g. `www/defs_spells.json`. The syntax of these files should be
self-explanatory.

These json files are then loaded and applied via the code in
`defs_apply.js`. If any new definition json files are added, the
`init` function must be tweaked so that the new json file is loaded
for processing.

## Announcing changes via Release Notes

Release Notes are defined in a json file and automatically inserted
into the landing and help pages of the tool.

When an announcement needs to be made via a Release Note, this can be
done by adjusted `www/release_notes.json`. The syntax of this file
should be self-explanatory.

Where appropriate, related files can be made available to download.
Such files should also be stored in the `www` sub-directory.

## Adding new Datasets

The Data Explorer was built to be a generalised interface for
exploring data, however as the only required use-case was for a
specific type of Count data, that is the only type supported
out-of-the-box.

The requirements for the supported type of Count data are:

* A column of Dates called `Date` (this must be a proper R "Date"
  class)
* A column of Counts called `Count`
* All other variables to be stored as a `factor` and be classifiers
  that are mutually exclusive, e.g. the variable "Gender" can split
  the Counts into "Male", "Female" and "Other", and the sum of the
  Counts for Male, Female and Other equals the Total Count (i.e.
  nobody is a member of multiple classes).

For data that follows these requirements, they can be added to the
Data Explorer by:

1. Saving the data as an `rda` file in the `shiny` directory (the name
of the object and the name of the file it is saved as must be equal).
2. In the `helper_funcs.R` within the `BetterCSVs` context, modify the
`extra_dnames` variable to include the name of the new dataset.

Congratulations, the data should now be available in the list of
datasets. It is advised that for any new data, appropriate dataset
definitions be written.
