requires 'File::Spec';
requires 'IO::String';
requires 'IPC::Open3';

requires 'Bio::Root::Root';
requires 'Bio::PrimarySeq';
requires 'Bio::LocatableSeq';
requires 'Bio::AlignIO';
requires 'Bio::TreeIO';
requires 'Bio::Matrix::PhylipDist';
requires 'Bio::Tools::Run::WrapperBase';
requires 'Bio::Tools::Run::Alignment::Clustalw';

requires 'perl', '5.010000';

on 'test' => sub {
    requires 'IO::Handle';
    requires 'Test::More';
};

