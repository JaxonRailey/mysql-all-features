# A list of trick and tips for MySQL

In this repo I show the use of triggers, stored procedures, functions and views through the classic example with products and sales, in a version deliberately revisited to facilitate teaching.

- only two tables, one for products, one for sales;
- each **product** has a field that indicates the **stock**;
- with each **sale**, the product inventory decreases;
- with each edit or delete of a row in the **sale** table, the product inventory is recalculated;
- a view takes care of displaying the revenues for each **product**;
- a custom function applies the discount based on the quantities ordered.

You can test the code by importing it on a database and playing on the **sale** table, try to add or remove somethings and product stocks will be automatically modified.

Tested and working on MySQL 8.

:star: **If you liked what I did, if it was useful to you or if it served as a starting point for something more magical let me know with a star** :green_heart:
