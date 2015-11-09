/* ------------------------------------------------------------------------------------------------------------------- *\
���� SignalView.h

��������� � ����� "���������������� �� ����� ����������"

�������� ���������� �������, ��������������� ��� ����������� ������������� �������� � �������.

������� ��������� (� stdafx.h)

(c) ������� �.�., 2014
��������� ��������� ����������� � ����� ������������� � ��� ����, � �������
��� �� �������� ���� ������ ����������������
\* ------------------------------------------------------------------------------------------------------------------- */
#pragma once
// ��������� ��������� �� ������� ������
#include "Tuning.h"

// ���������������� ���� �������� �������� ��� �����������
#define SV_NONE (-1)		// �������� �������
#define SV_SIN 1		// ���������
#define SV_COS 2		// �����������
#define SV_SQUARE 3		// ������������� ������
#define SV_SAW	4		// ������������

// ��������� �������
#define AMPLITUDE 100.

class SignalView
{
private:
	// �������� ������
	int		_type;			// ��� �����
	COLORREF _color_src;	// ���� �����

	// ��������������� ������
	double	*_recovered;		// ����� �������� (FT_SIGNAL_SIZE)
	COLORREF _color_rec;		// ���� �����
public:
	SignalView(COLORREF color_src = RGB(0, 0, 0xFF), COLORREF color_rec = RGB(0xF0, 0, 0x40)) :
		_color_src(color_src), _type(-1), _color_rec(color_rec), _recovered(NULL) 	{}
	~SignalView() { if (NULL != _recovered) delete _recovered; }
	// ������� ����������� ������� � �������� �������
	void View(HDC hDC, RECT Area) {
	// hDC   - �������� ���������� ��� �����������
	// Area  - ������������� � ��������� ����������, ������� ����������� �������
		HPEN hpen;
		HGDIOBJ oldpen;
		double f, x;
		long i;
		long width = Area.right - Area.left;
		double amplitude = (Area.bottom-Area.top) / 2;

		// ����� (0,0)
		POINT zz;
		zz.x = Area.left;
		zz.y = (Area.top + Area.bottom) / 2;
		// ������������ ��� ���������
		MoveToEx(hDC, zz.x, Area.top, NULL);
		LineTo(hDC, zz.x, Area.bottom);
		// �������������� ��� ���������
		MoveToEx(hDC, zz.x, zz.y, NULL);
		LineTo(hDC, Area.right, zz.y);

		// ��������� ��������� ������� 
		hpen = CreatePen(PS_SOLID, 1, _color_src);
		oldpen = SelectObject(hDC, hpen);
		switch (_type)
		{
		case SV_NONE:
			break;
		case SV_SIN:
			MoveToEx(hDC, zz.x, zz.y, NULL);
			for (i = 0; i < width; i++)
			{
				x = double(i) * 2. * M_PI / double(width);
				f = amplitude * sin(x);
				LineTo(hDC, zz.x + i, zz.y - int(f));
			}
			LineTo(hDC, zz.x + width, zz.y );
			break;
		case SV_COS:
			MoveToEx(hDC, zz.x, Area.top, NULL);
			for (i = 0; i < width; i++)
			{
				x = double(i) * 2. * M_PI / double(width);
				f = amplitude * cos(x);
				LineTo(hDC, zz.x + i, zz.y - int(f));
			}
			LineTo(hDC, zz.x + width, Area.top );
			break;
		case SV_SQUARE:
			MoveToEx(hDC, zz.x, Area.top, NULL);
			LineTo(hDC, (Area.left + Area.right) / 2, Area.top);
			LineTo(hDC, (Area.left + Area.right) / 2, Area.bottom);
			LineTo(hDC, Area.right, Area.bottom);
			LineTo(hDC, Area.right, Area.top);
			break;
		case SV_SAW:
			MoveToEx(hDC, zz.x, zz.y, NULL);
			LineTo(hDC, (Area.left + Area.right) / 2, Area.top);
			LineTo(hDC, (Area.left + Area.right) / 2, Area.bottom);
			LineTo(hDC, Area.right, zz.y);
			break;

		default:
			break;
		}
		DeleteObject(hpen);

		// ��������� ���������������� �������
		if (NULL != _recovered) {
			hpen = CreatePen(PS_SOLID, 1, _color_rec);
			SelectObject(hDC, hpen);

			double step = double(width) / double(FT_SIGNAL_SIZE);
			POINT pnt;
			for (i = 0; i < FT_SIGNAL_SIZE; i++) {
				pnt.x = zz.x + long(round(double(i) * step));
				pnt.y = zz.y - long(round(_recovered[i] / AMPLITUDE*amplitude));
				Ellipse(hDC, pnt.x - 3, pnt.y - 3, pnt.x + 3, pnt.y + 3);
			}
			pnt.x = Area.right;
			pnt.y = zz.y - long(round(_recovered[0] / AMPLITUDE*amplitude));
			Ellipse(hDC, pnt.x - 3, pnt.y - 3, pnt.x + 3, pnt.y + 3);

			DeleteObject(hpen);
		}
		SelectObject(hDC, oldpen);	
	}

	// ������� ��������� � ������������ ������� ��������� ������� �������� �����
	void SetSource(int Type) {
		_type = Type;
		if (NULL != _recovered)
			delete _recovered;
		_recovered = NULL;
	}

	// ������� ��������� � ������������ ������� ���������������� ������� �� ��������
	void SetRecovered(signal_type* Recovered)
	{
		if (_type != SV_NONE){
			if (NULL == _recovered )
				_recovered = new double[FT_SIGNAL_SIZE];
			for (int i = 0; i < FT_SIGNAL_SIZE; i++)
				_recovered[i] = double(Recovered[i]);
		}
	}

	void GetSignalSample(signal_type* Sample)
	{
		double x, f;
		switch (_type){
		case SV_SIN:
			for (int i = 0; i < FT_SIGNAL_SIZE; i++){
				x = double(i) * 2. * M_PI / double(FT_SIGNAL_SIZE);
				f = AMPLITUDE * sin(x);
				Sample[i] = signal_type(f);
			}
			break;
		case SV_COS:
			for (int i = 0; i < FT_SIGNAL_SIZE; i++){
				x = double(i) * 2. * M_PI / double(FT_SIGNAL_SIZE);
				f = AMPLITUDE * cos(x);
				Sample[i] = signal_type(f);
			}
			break;
		case SV_SQUARE:
			for (int i = 0; i < FT_SIGNAL_SIZE / 2; i++)
				Sample[i] = signal_type(AMPLITUDE);
			for (int i = FT_SIGNAL_SIZE / 2; i < FT_SIGNAL_SIZE ; i++)
				Sample[i] = signal_type(-AMPLITUDE);
			break;
		case SV_SAW:
			for (int i = 0; i < FT_SIGNAL_SIZE / 2; i++)
				Sample[i] = signal_type(double(i)*double(AMPLITUDE)*2. / double(FT_SIGNAL_SIZE));
			for (int i = FT_SIGNAL_SIZE / 2; i < FT_SIGNAL_SIZE ; i++)
				Sample[i] = signal_type(double(i)*double(AMPLITUDE)*2. / double(FT_SIGNAL_SIZE) - double(AMPLITUDE)*2.);
			break;
		default:
			break;
		}
	}
};

class SpectrumView{
private:
	COLORREF _color;	// ���� �������
	double* _spectrum;	// ������ ��������
public:
	SpectrumView(COLORREF color = RGB(0,0x80,0x20)) : _color(color), _spectrum(NULL) {}
	~SpectrumView() { if (NULL != _spectrum) delete _spectrum; }
	// ������� ��������� ������� � ������������ ������� �� ��������
	void SetSpectrum(spectrum_type* Spectrum) {
		if (NULL == _spectrum)
			_spectrum = new double[FT_SIGNAL_SIZE];
		for (int i = 0; i < FT_SIGNAL_SIZE; i++)
			_spectrum[i] = double(Spectrum[i]);
	}
	void View(HDC hDC, RECT Area) {
		// hDC   - �������� ���������� ��� �����������
		// Area  - ������������� � ��������� ����������, ������� ����������� �������
		HPEN hpen;
		HGDIOBJ oldpen;
		// ����� (0,0)
		POINT zz;
		zz.x = Area.left;
		zz.y = (Area.top + Area.bottom) / 2;
		// ������ � ������
		int width = Area.right - Area.left;
		int hight = Area.bottom - Area.top;
		// ������������ ��� ���������
		MoveToEx(hDC, zz.x, Area.top, NULL);
		LineTo(hDC, zz.x, Area.bottom);
		// �������������� ��� ���������
		MoveToEx(hDC, zz.x, zz.y, NULL);
		LineTo(hDC, Area.right, zz.y);

		if (NULL != _spectrum){
			// ��������� ���������
			double a_min = DBL_MAX;
			double a_max = DBL_MIN;
			for (int i = 0; i < FT_SIGNAL_SIZE; i++)
			{
				a_max = max(a_max, _spectrum[i]);
				a_min = min(a_min, _spectrum[i]);
			}
			if (a_max < 0)a_max = -a_max;
			if (a_min < 0)a_min = -a_min;

			double amplitude = double(hight) / max(a_max, a_min) / 2.;

			hpen = CreatePen(PS_SOLID, 1, _color);
			oldpen = SelectObject(hDC, hpen);
			double step = double(width) / double(FT_SIGNAL_SIZE);
			POINT pnt;
			for (int i = 0; i < FT_SIGNAL_SIZE; i++) {
				pnt.x = zz.x + long(round(double(i) * step));
				pnt.y = zz.y - long(round(_spectrum[i] * amplitude));
				MoveToEx(hDC, pnt.x, pnt.y, NULL);
				LineTo(hDC, pnt.x, zz.y);
				Ellipse(hDC, pnt.x - 3, pnt.y - 3, pnt.x + 3, pnt.y + 3);
			}
			DeleteObject(hpen);
			SelectObject(hDC, oldpen);
		}
	}
	void Clear(void) {
		if (_spectrum != NULL){
			delete _spectrum;
			_spectrum = NULL;
		}
	}
};