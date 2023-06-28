#include <TFile.h>
#include <TTree.h>
#include <TCanvas.h>
#include <TH1.h>
#include <TObjArray.h>
#include <iostream>

void drawTracksvsEventsFromTree(const char *fName, const char *numElec, const char *outName) {
  TFile * infile = TFile::Open(fName, "READ");
  TTree * tree = (TTree*)infile->Get("LDMX_Events");
  TCanvas * c1 = new TCanvas("c1", "plotting canvas", 600, 500);
  TH1F * myHist;
  c1->cd(); 

  std::string trackPassName = "sim"; // overlay for signal 2-4e, overlay for signal, sim for large inclusive, rereco for everything else
  std::string trackCollection = Form("@TriggerPadTracks_%s", trackPassName.c_str());

  TObjArray Hlist(0);
  
  tree->SetLineWidth(2);
  tree->SetLineStyle(1);

  // histogram of number of events in each track
  tree->Draw(Form("%s.size() >> htracks(6, 0, 6)", trackCollection.c_str()));
  myHist=(TH1F*)gDirectory->Get("htracks");
  myHist->SetName("tracksVsEvents");
  Hlist.Add(myHist);
  
  cout << outName << endl;

  TFile * outfile = new TFile(outName, "RECREATE");

  Hlist.Write();
  outfile->Close();
}
