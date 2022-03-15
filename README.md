# SYNOPSIS

    #!/usr/bin/perl -Tw
    use strict;

    use Bio::Tools::Phylo::PAML;

    # need to specify the output file name (or a fh) (defaults to
    # -file => "codeml.mlc"); also, optionally, the directory in which
    # the other result files (rst, 2ML.dS, etc) may be found (defaults
    # to "./")
    my $parser = Bio::Tools::Phylo::PAML->new
      (-file => "./results/mlc", -dir => "./results/");

    # get the first/next result; a Bio::Tools::Phylo::PAML::Result object,
    # which isa Bio::SeqAnalysisResultI object.
    my $result = $parser->next_result();

    # get the sequences used in the analysis; returns Bio::PrimarySeq
    # objects (OTU = Operational Taxonomic Unit).
    my @otus = $result->get_seqs();

    # codon summary: codon usage of each sequence [ arrayref of {
    # hashref of counts for each codon } for each sequence and the
    # overall sum ], and positional nucleotide distribution [ arrayref
    # of { hashref of frequencies for each nucleotide } for each
    # sequence and overall frequencies ]:
    my ($codonusage, $ntdist) = $result->get_codon_summary();

    # example manipulations of $codonusage and $ntdist:
    printf "There were %d %s codons in the first seq (%s)\n",
      $codonusage->[0]->{AAA}, 'AAA', $otus[0]->id();
    printf "There were %d %s codons used in all the sequences\n",
      $codonusage->[$#{$codonusage}]->{AAA}, 'AAA';
    printf "Nucleotide %c was present %g of the time in seq %s\n",
      'A', $ntdist->[1]->{A}, $otus[1]->id();

    # get Nei & Gojobori dN/dS matrix:
    my $NGmatrix = $result->get_NGmatrix();

    # get ML-estimated dN/dS matrix, if calculated; this corresponds to
    # the runmode = -2, pairwise comparison usage of codeml
    my $MLmatrix = $result->get_MLmatrix();

    # These matrices are length(@otu) x length(@otu) "strict lower
    # triangle" 2D-matrices, which means that the diagonal and
    # everything above it is undefined.  Each of the defined cells is a
    # hashref of estimates for "dN", "dS", "omega" (dN/dS ratio), "t",
    # "S" and "N".  If a ML matrix, "lnL" and "kappa" will also be defined.
    printf "The omega ratio for sequences %s vs %s was: %g\n",
      $otus[0]->id, $otus[1]->id, $MLmatrix->[0]->[1]->{omega};

    # with a little work, these matrices could also be passed to
    # Bio::Tools::Run::Phylip::Neighbor, or other similar tree-building
    # method that accepts a matrix of "distances" (using the LOWTRI
    # option):
    my $distmat = [ map { [ map { $$_{omega} } @$_ ] } @$MLmatrix ];

    # for runmode's other than -2, get tree topology with estimated
    # branch lengths; returns a Bio::Tree::TreeI-based tree object with
    # added PAML parameters at each node
    my ($tree) = $result->get_trees();
    for my $node ($tree->get_nodes()) {
       # inspect the tree: the "t" (time) parameter is available via
       # $node->branch_length(); all other branch-specific parameters
       # ("omega", "dN", etc.) are available via
       # ($omega) = $node->get_tag_values('omega');
    }

    # if you are using model based Codeml then trees are stored in each
    # modelresult object
    for my $modelresult ( $result->get_NSSite_results ) {
      # model M0, M1, etc
      print "model is ", $modelresult->model_num, "\n";
      my ($tree) = $modelresult->get_trees();
      for my $node ($tree->get_nodes()) {
       # inspect the tree: the "t" (time) parameter is available via
       # $node->branch_length(); all other branch-specific parameters
       # ("omega", "dN", etc.) are available via
       # ($omega) = $node->get_tag_values('omega');
     }
    }

    # get any general model parameters: kappa (the
    # transition/transversion ratio), NSsites model parameters ("p0",
    # "p1", "w0", "w1", etc.), etc.
    my $params = $result->get_model_params();
    printf "M1 params: p0 = %g\tp1 = %g\n", $params->{p0}, $params->{p1};

    # parse AAML result files
    my $aamat = $result->get_AADistMatrix();
    my $aaMLmat = $result->get_AAMLDistMatrix();

# DESCRIPTION

This module is used to parse the output from the PAML programs codeml,
baseml, basemlg, codemlsites and yn00.  You can use the
Bio::Tools::Run::Phylo::PAML::\* modules to actually run some of the
PAML programs, but this module is only useful to parse the output.

This module has fledgling support for PAML version 4.3a (October 2009).
Please report any problems to the mailing list (see FEEDBACK below).

## parse\_codeml example

    use Bio::Tools::Phylo::PAML;

    my $parser = new Bio::Tools::Phylo::PAML(-file    => shift,
                                             -verbose => shift);

    my $result = $parser->next_result;
    my @otus = $result->get_seqs();
    my $MLmatrix = $result->get_MLmatrix();
    my $NGmatrix = $result->get_NGmatrix();

    # These matrices are length(@otu) x length(@otu) "strict lower
    # triangle" 2D-matrices, which means that the diagonal and
    # everything above it is undefined.  Each of the defined cells is a
    # hashref of estimates for "dN", "dS", "omega" (dN/dS ratio), "t",
    # "S" and "N".  If a ML matrix, "lnL" will also be defined.

    @otus = $result->get_seqs();
    $MLmatrix = $result->get_MLmatrix();
    $NGmatrix = $result->get_NGmatrix();
    for( my $i=0;$i<scalar @$MLmatrix;$i++) {
        for( my $j = $i+1; $j < scalar @{$MLmatrix->[$i]}; $j++ ) {
            printf "The ML omega ratio for sequences %s vs %s was: %g\n",
              $otus[$i]->id, $otus[$j]->id, $MLmatrix->[$i]->[$j]->{omega};
        }
    }

    for( my $i=0;$i<scalar @$MLmatrix;$i++) {
        for( my $j = $i+1; $j < scalar @{$MLmatrix->[$i]}; $j++ ) {
            printf "The NG omega ratio for sequences %s vs %s was: %g\n",
              $otus[$i]->id, $otus[$j]->id, $NGmatrix->[$i]->[$j]->{'omega'};
        }
    }

# TO DO

Implement get\_posteriors(). For NSsites models, obtain arrayrefs of
posterior probabilities for membership in each class for every
position; probabilities correspond to classes w0, w1, ... etc.

    my @probs = $result->get_posteriors();

    # find, say, positively selected sites!
    if ($params->{w2} > 1) {
      for (my $i = 0; $i < @probs ; $i++) {
        if ($probs[$i]->[2] > 0.5) {
           # assumes model M1: three w's, w0, w1 and w2 (positive selection)
           printf "position %d: (%g prob, %g omega, %g mean w)\n",
             $i, $probs[$i]->[2], $params->{w2}, $probs[$i]->[3];
        }
      }
    } else { print "No positive selection found!\n"; }

# TODO

RST parsing -- done, Avilella contributions bug#1506, added by jason 1.29
            -- still need to parse in joint probability and non-syn changes
               at site table

    Title   : new
    Usage   : my $obj = Bio::Tools::Phylo::PAML->new(%args);
    Function: Builds a new Bio::Tools::Phylo::PAML object
    Returns : Bio::Tools::Phylo::PAML
    Args    : Hash of options: -file, -fh, -dir
              -file (or -fh) should contain the contents of the PAML
                    outfile;
              -dir is the (optional) name of the directory in
                   which the PAML program was run (and includes other
                   PAML-generated files from which we can try to gather data)

    Title   : next_result
    Usage   : $result = $obj->next_result();
    Function: Returns the next result available from the input, or
              undef if there are no more results.
    Example :
    Returns : a Bio::Tools::Phylo::PAML::Result object
    Args    : none

# AUTHOR

AUTHOR: Jason Stajich <jason@bioperl.org>
AUTHOR: Aaron Mackey <amackey@virginia.edu>
OWNER: Jason Stajich <jason@bioperl.org>
OWNER: Aaron Mackey <amackey@virginia.edu>

AUTHOR: Albert Vilella <avilella@gmail.com>
AUTHOR: Sendu Bala <bix@sendu.me.uk>
AUTHOR: Dave Messina <dmessina@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 202:

    Unknown directive: =method

- Around line 228:

    Unknown directive: =method

- Around line 232:

    Unknown directive: =method
