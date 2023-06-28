#include <TStyle.h>
#include <TFile.h>
#include <TTree.h>
#include <TCanvas.h>
#include <TH1.h>
#include <TH2.h>
#include <TObjArray.h>
#include <iostream>
#include <TLegend.h>
#include <vector>
#include <string>

void confusionMatrix(const char *suffix)
{
    gStyle->SetOptStat(0);
    bool isFirst = true;
    int totalEvents = 0;
    TFile* outfile = new TFile(Form("confusion-matrix-%s.root", suffix), "RECREATE");
    isFirst = true;

    // initializations
    TCanvas* c_normal = new TCanvas("c_normal", "normal event canvas", 600, 500);
    c_normal->SetRightMargin(1.5*c_normal->GetRightMargin());
    c_normal->cd();
    TH2F* confusion_matrix = new TH2F("confusion-matrix", Form("Counted vs. True electrons %s", suffix), 4, 1, 5, 6, 0, 6);

    for (int mult = 1; mult <= 4; mult++) {
        totalEvents = 0;
        TH2F* temp = new TH2F("temp", Form("Counted vs. True electrons %s", suffix), 4, 1, 5, 6, 0, 6);
        TFile* infile = TFile::Open(Form("inclusive%ie-%s.root", mult, suffix));
        TH1* h_counted = (TH1 *)infile->Get("tracksVsEvents"); 
        for (int bin = 1; bin <= h_counted->GetNbinsX(); bin++) {
            temp->Fill(mult, bin - 1, h_counted->GetBinContent(bin));
            totalEvents += h_counted->GetBinContent(bin);
        }
        temp->Scale(1./totalEvents);
        confusion_matrix->Add(temp);

    }
    confusion_matrix->SetXTitle("True e-");
    confusion_matrix->SetYTitle("Counted e-");
    confusion_matrix->GetXaxis()->SetNdivisions(6);
    confusion_matrix->GetYaxis()->SetNdivisions(6);
    confusion_matrix->Draw("text colz");

    outfile->Write();
    c_normal->SaveAs(Form("confusion-matrix-%s.png", suffix));

    outfile->Close();
}
