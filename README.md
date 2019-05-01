RMQV
=======
This repository contains the necessary data structures and algorithms to perform a) RM3
query expansion, b) Rank fusion, and c) A combination of these approaches.

This framework was used in the results from the following work:
* Rodger Benham, J. Shane Culpepper, Luke Gallagher, Xiaolu Lu, Joel Mackenzie, _Towards Efficient and Effective Query Variant Generation_, DESIRES 2018.


Building Collections
--------------------
### Inverted Index ###
First, we start with an Indri index. We then convert it to a ds2i index using the `indri_to_ds2i`
binary in the `format_collection` directory. 

Apart from the normal ds2i files (which a description can be found at the bottom of this README),
a document map and lexicon are also output.

Next, once you have a ds2i formatted collection, you can build the PEF index and wand data required
for top-*k* search. This is well documented below (in the ds2i section of this README). Note that
I always use `opt` encoding. VBMW indexes need to be built with caution: the parameter 
`fixed_cost_wand_partition` found in
`configuration.hpp` will impact the optimization of block sizes, and you may end up with an index with
a strange/unexpected average block size. This is the lambda parameter from the VBMW paper.
If you only care about fixed BMW indexes, you can use
the `block_size` parameter (also in `configuration.hpp`) to create a normal BMW index with the 
provided block size.  

### Document Vectors ###
The document vector code is entirely contained within the `docvector/` directory. Build the code,
and then use `create_docvectors` to generate the document vector for the collection. This is
similar to the creation of the inverted indexes (it takes a ds2i collection as input). You can
also provide a stoplist to ensure your document vectors do not contain certain terms.

Query Format
------------
Queries are of the form `ID t1 t2 ... tk` where terms should be appropriately stemmed/stopped before
being passed into the engine. A Krovetz stemmer has been provided in the `format_queries` directory.


Param files
-----------
The supplied binaries that enable RM3 expansion take param files as arguments. These are described
as follows.
```
raw_collection=/path/to/ds2i/collection/prefix
inverted_index=/path/to/ds2i/index/example-opt-pef.idx
forward_index=/path/to/ds2i/forward/example-forward.idx
wand_file=/path/to/ds2i/index/example.bmw
docs_to_expand=50
terms_to_expand=100
lambda_expand=0.1
final_k=1000
gen_queries=100
```
Note that:
* `inverted_index` is created using `create_freq_index`, 
* `wand_file is created with `create_wand_data`, 
* `forward_index` is created using `create_docvectors`,
* `docs_to_expand` is the number of documents to use for RM3 expansion,
* `terms_to_expand` is the number of terms to expand from the RM (when creating the new, expanded query),
* `lambda_expand` is the weight given to the original query, (1-lambda is given to the expanded query),
* `final_k` is the final top-k list size, and
* `gen_queries` is the number of queries to generate if using the sampler (`external_corpus_sampler`). 

Walk through
------------
We provide a basic end-to-end walkthrough in the `example` directory.

ds2i
====

Data Structures for Inverted Indexes (ds2i) is a library of data structures to
represent the integer sequences used in inverted indexes.

This code was used in the experiments of the following papers.

* Giuseppe Ottaviano, Rossano Venturini, _Partitioned Elias-Fano Indexes_,
  ACM SIGIR 2014.

* Giuseppe Ottaviano, Nicola Tonellotto, Rossano Venturini, _Optimal Space-Time
  Tradeoffs for Inverted Indexes_, ACM WSDM 2015.

* Antonio Mallia, Giuseppe Ottaviano, Elia Porciani, Nicola Tonellotto, Rossano Venturini, _Faster BlockMax WAND with variable-sized blocks_, ACM SIGIR 2017.


Building the code
-----------------

The code is tested on Linux with GCC 5.4.0 and macOS Sierra with Clang.

The following dependencies are needed for the build.

* CMake >= 2.8, for the build system
* Boost >= 1.51

If you do not have Boost installed, run `./boost.sh` first.

The code depends on several git submodules. If you have cloned the repository
without `--recursive`, you will need to perform the following commands before
building:

    $ git submodule update --init --recursive

To build the code:

    $ mkdir build
    $ cd build
    $ cmake .. -DCMAKE_BUILD_TYPE=Release
    $ make

It is also preferable to perform a `make test`, which runs the unit tests.

If you are having problems with your boost version in CMake, download and compile the 
latest version using the `./boost.sh` script supplied.

For further information about ds2i and variable block-max wand, please visit the original repos:
* [ds2i](https://github.com/ot/ds2i)
* [vbmw](https://github.com/rossanoventurini/Variable-BMW)


Collection input format
-----------------------

A _binary sequence_ is a sequence of integers prefixed by its length, where both
the sequence integers and the length are written as 32-bit little-endian
unsigned integers.

A _collection_ consists of 3 files, `<basename>.docs`, `<basename>.freqs`,
`<basename>.sizes`.

* `<basename>.docs` starts with a singleton binary sequence where its only
  integer is the number of documents in the collection. It is then followed by
  one binary sequence for each posting list, in order of term-ids. Each posting
  list contains the sequence of document-ids containing the term.

* `<basename>.freqs` is composed of a one binary sequence per posting list, where
  each sequence contains the occurrence counts of the postings, aligned with the
  previous file (note however that this file does not have an additional
  singleton list at its beginning).

* `<basename>.sizes` is composed of a single binary sequence whose length is the
  same as the number of documents in the collection, and the i-th element of the
  sequence is the size (number of terms) of the i-th document.


We thank the original authors for providing their code:

* Antonio Mallia <me@antoniomallia.it>
* Giuseppe Ottaviano <giuott@gmail.com>
* Elia Porciani <elia.porciani@gmail.com>
* Nicola Tonellotto <nicola.tonellotto@isti.cnr.it>
* Rossano Venturini <rossano@di.unipi.it>
