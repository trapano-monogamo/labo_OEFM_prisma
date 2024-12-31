#include <iostream>
#include <fstream>
#include <vector>

#include "TApplication.h"
#include "TCanvas.h"
#include "TGraphErrors.h"
#include "TF1.h"
#include "TLegend.h"
#include "TAxis.h"

using namespace std;

struct Measure {
	double x,ex,y,ey;

	friend istream& operator>>(istream& in, Measure& m) {
		in >> m.x >> m.ex >> m.y >> m.ey;
		return in;
	}
	friend ostream& operator<<(ostream& out, Measure& m) {
		out <<  "{" << m.x << " +- " << m.ex
			<< ", " << m.y << " +- " << m.ey << "}";
		return out;
	}
};


vector<Measure> read_file(const char* filename) {
	vector<Measure> res;
	ifstream in(filename);

	if (!in.good()) {
		cerr << "Could not open file '" << filename << "'" << endl;
		throw;
	}

	Measure m;
	while (in >> m) { res.push_back(m); }
	
	return res;
}


int main(int argc, char** argv) {
	if (argc < 2) {
		cerr << "Not enoug arguments. Usage: ./plot <lin_reg_data>.csv" << endl;
		return -1;
	}

	char* filename = argv[1];
	vector<Measure> data = read_file(filename);

	TApplication app("linear regression",0,0);
	TGraphErrors graph;

	for (int i=0; i<data.size()-1; i++) {
		graph.SetPoint(i, data[i].x, data[i].y);
		graph.SetPointError(i, data[i].ex, data[i].ey);
	}

	// TF1 cauchy_line("lin_reg", "[0] * x + [1]", data[0].x, data[data.size()-1].x);
	TF1 cauchy_line("lin_reg", "[0] * x + [1]", 1., 0.);
	graph.Fit(&cauchy_line);

	TCanvas canvas("linear regression");
	canvas.SetGrid();

	graph.SetMarkerStyle(20);
	graph.SetMarkerSize(1.5);

	graph.Draw("AP");
	graph.SetTitle("Approssimazione di Cauchy");
	graph.GetXaxis()->SetTitle("1/#lambda^{2} [#AA^{-2}]");
	graph.GetXaxis()->CenterTitle(true);
	graph.GetYaxis()->SetTitle("n(#lambda)");
	graph.GetYaxis()->CenterTitle(true);

	TLegend legend(0.15,0.7,0.3,0.85);
	legend.AddEntry(&graph,"dati","LE");
	legend.AddEntry(&cauchy_line,"fit: #frac{a}{#lambda^{2}} + b","L");
	legend.Draw();

	cout << endl
		 << "a       = " << cauchy_line.GetParameter(0) << " +- " << cauchy_line.GetParError(0) << endl
		 << "b       = " << cauchy_line.GetParameter(1) << " +- " << cauchy_line.GetParError(1) << endl
		 << "p(chi2) = " << cauchy_line.GetProb() << endl;

	app.Run();
}
