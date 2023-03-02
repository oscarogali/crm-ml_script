% % CONCATENATING CAPACITANCE-RESISTANCE MODEL AND MACHINE LEARNING       % %
% Machine Learning Approaches used are: (i.) Support Vector Machines (SVM)  %
% (SVM); (ii.) Decision Trees (DTs); (iii.) Radial Basis Neural Networks    %
% (RBNN); and (iv.) Long-Short Term Memory (LSTM).                          %

% The Neural Networks (RBNN and LSTM) have 1 HL and 1 OL. Neurons in each   %
% HL (for RBNN) was determined by trial-and-error approach (using           %
% 'for loop' to evaluate MSE's for different number of neurons.             %

% Time inclusive in input for CRM-ML but, not in ML. All producers should   %
% have same length of time (history). Producer time constant is one of      %
% inputs in CRM-ML. Input XLSX File is CRMd_Data_BuffSD2.xlsx file.         %

% THIS IS CRM-ML FOR BUFFALO FIELD, SOUTH DAKOTA.                           %

clear; clc; close all

tic         % Simulation Start Time

%% IMPORTING DATA FOR ML AND CRM-ML
% First Column = Producer Name;
% Second Column = Time [days];
% Third II Columns = ij Well-Pair Distance;
% Fourth II Columns = ij Connectivity Indices (lambda_ij);
% Fifth II Columns = ij Time Constants (tau_ij);
% Sixth II Columns = ith Injection Rates;
% Seventh 1 Column = j Time Constants (tau_j);
% Eighth 1 Column = Target Qj.

% Number of Producers and Injectors
JJ=8;       % Number of Producers
II=5;       % Number of Injectors

% Old Format
[X,X1,Data]=xlsread(...
'C:\Users\Oscar Ogali\Documents\MATLAB_OIOO\OIOO_CRMML_Sims\CRMd_Data_BuffSD2',...  
    'CRM-ML_Data');         %#ok
[X2_1,X2_2]=xlsread(...
'C:\Users\Oscar Ogali\Documents\MATLAB_OIOO\OIOO_CRMML_Sims\CRMd_Data_BuffSD2',...  
    'CRM_Rates');           %#ok

% Using readcell is recommended but, I have not figured out how.
% X1 = readcell('CRMd_Data4.xlsx','Sheet','CRM-ML_Data');
% X2 = readcell('CRMd_Data4.xlsx','Sheet','CRM_Rates');

% Collecting variables
NN = size(X,1)/JJ;     % Time-steps in Data
t = X2_1(:,1);         % Time, [days]

% CRM-generated Production Rates, [STB/day]
% Producers:
% TM1-7FH; NJ-19H; P1-30; BR E-29H; K43-29; TA-1; CB34-31H; CB14-31NH.
qCRM_P1=X2_1(:,2); qCRM_P2=X2_1(:,3); qCRM_P3=X2_1(:,4); qCRM_P4=X2_1(:,5);
qCRM_P5=X2_1(:,6); qCRM_P6=X2_1(:,7); qCRM_P7=X2_1(:,8); qCRM_P8=X2_1(:,9);

% Portion of Data used in Training the ANN and determining ANN Architecture
% History = 189 mth. Training and Val'n = 177 mth. Pred'n = 12 mth.
NNA = 177;

ProdName1(:,1)=string(Data(3:end,1));   % Column of Producer Names
GG = zeros(NN,size(X,2)); Prod1_Data=GG; Prod2_Data=GG; Prod3_Data=GG;
Prod4_Data=GG; Prod5_Data=GG; Prod6_Data=GG; Prod7_Data=GG; Prod8_Data=GG; 
% Initializations
for i=1:NN
    % Producer P-01 (TM1-7FH)
    if strcmp(ProdName1(i),'P-01')
        Prod1_Data(i,:)=X(i,:);
    end
    % Producer P-02 (NJ-19H)
    if strcmp(ProdName1(NN+i),'P-02')
        Prod2_Data(i,:)=X(NN+i,:);
    end
    % Producer P-03 (P1-30)
    if strcmp(ProdName1((2*NN)+i),'P-03')
        Prod3_Data(i,:)=X((2*NN)+i,:);
    end
    % Producer P-04 (BR E-39H)
    if strcmp(ProdName1((3*NN)+i),'P-04')
        Prod4_Data(i,:)=X((3*NN)+i,:);   
    end
    % Producer P-05 (K43-29)
    if strcmp(ProdName1((4*NN)+i),'P-05')
        Prod5_Data(i,:)=X((4*NN)+i,:);   
    end
    % Producer P-06 (TA-1)
    if strcmp(ProdName1((5*NN)+i),'P-06')
        Prod6_Data(i,:)=X((5*NN)+i,:);   
    end
    % Producer P-07 (CB34-31H)
    if strcmp(ProdName1((6*NN)+i),'P-07')
        Prod7_Data(i,:)=X((6*NN)+i,:);   
    end
    % Producer P-08 (CB14-31NH)
    if strcmp(ProdName1((7*NN)+i),'P-08')
        Prod8_Data(i,:)=X((7*NN)+i,:);   
    end
end
clear i GG X X1 X2_1 X2_2

%% NORMALIZING INPORTED DATA FOR CRM-ML AND ML

GG = zeros(NN,((4*II)+3));  % Initializations
Prod1_Data1 = GG; Prod2_Data1 = GG; Prod3_Data1 = GG; Prod4_Data1 = GG;     
Prod5_Data1 = GG; Prod6_Data1 = GG; Prod7_Data1 = GG; Prod8_Data1 = GG;     

% Producer P-01
for j1=1:((4*II)+3)
    if max(Prod1_Data(:,j1)) == min(Prod1_Data(:,j1))
        Prod1_Data1(:,j1) = 1;
    else
        for i1=1:NN
            Prod1_Data1(i1,j1) = (Prod1_Data(i1,j1)-min(Prod1_Data(:,j1)))./...
                (max(Prod1_Data(:,j1))-min(Prod1_Data(:,j1)));
        end
    end
end

% Producer P-02
for j2=1:((4*II)+3)
    if max(Prod2_Data(:,j2)) == min(Prod2_Data(:,j2))
        Prod2_Data1(:,j2) = 1;
    else
        for i2=1:NN
            Prod2_Data1(i2,j2) = (Prod2_Data(i2,j2)-min(Prod2_Data(:,j2)))./...
                (max(Prod2_Data(:,j2))-min(Prod2_Data(:,j2)));
        end
    end
end

% Producer P-03
for j3=1:((4*II)+3)
    if max(Prod3_Data(:,j3)) == min(Prod3_Data(:,j3))
        Prod3_Data1(:,j3) = 1;
    else
        for i3=1:NN
            Prod3_Data1(i3,j3) = (Prod3_Data(i3,j3)-min(Prod3_Data(:,j3)))./...
                (max(Prod3_Data(:,j3))-min(Prod3_Data(:,j3)));
        end
    end
end

% Producer P-04
for j4=1:((4*II)+3)
    if max(Prod4_Data(:,j4)) == min(Prod4_Data(:,j4))
        Prod4_Data1(:,j4) = 1;
    else
        for i4=1:NN
            Prod4_Data1(i4,j4) = (Prod4_Data(i4,j4)-min(Prod4_Data(:,j4)))./...
                (max(Prod4_Data(:,j4))-min(Prod4_Data(:,j4)));
        end
    end
end

% Producer P-05
for j5=1:((4*II)+3)
    if max(Prod5_Data(:,j5)) == min(Prod5_Data(:,j5))
        Prod5_Data1(:,j5) = 1;
    else
        for i5=1:NN
            Prod5_Data1(i5,j5) = (Prod5_Data(i5,j5)-min(Prod5_Data(:,j5)))./...
                (max(Prod5_Data(:,j5))-min(Prod5_Data(:,j5)));
        end
    end
end

% Producer P-06
for j6=1:((4*II)+3)
    if max(Prod6_Data(:,j6)) == min(Prod6_Data(:,j6))
        Prod6_Data1(:,j6) = 1;
    else
        for i6=1:NN
            Prod6_Data1(i6,j6) = (Prod6_Data(i6,j6)-min(Prod6_Data(:,j6)))./...
                (max(Prod6_Data(:,j6))-min(Prod6_Data(:,j6)));
        end
    end
end

% Producer P-07
for j7=1:((4*II)+3)
    if max(Prod7_Data(:,j7)) == min(Prod7_Data(:,j7))
        Prod7_Data1(:,j7) = 1;
    else
        for i7=1:NN
            Prod7_Data1(i7,j7) = (Prod7_Data(i7,j7)-min(Prod7_Data(:,j7)))./...
                (max(Prod7_Data(:,j7))-min(Prod7_Data(:,j7)));
        end
    end
end

% Producer P-08
for j8=1:((4*II)+3)
    if max(Prod8_Data(:,j8)) == min(Prod8_Data(:,j8))
        Prod8_Data1(:,j8) = 1;
    else
        for i8=1:NN
            Prod8_Data1(i8,j8) = (Prod8_Data(i8,j8)-min(Prod8_Data(:,j8)))./...
                (max(Prod8_Data(:,j8))-min(Prod8_Data(:,j8)));
        end
    end
end

% COLLATING INPUT DATA FOR MACHINE LEARNING ONLY
Prod1_IDat1 = Prod1_Data1(:,((3*II)+2):((4*II)+1));
Prod2_IDat1 = Prod2_Data1(:,((3*II)+2):((4*II)+1));
Prod3_IDat1 = Prod3_Data1(:,((3*II)+2):((4*II)+1));
Prod4_IDat1 = Prod4_Data1(:,((3*II)+2):((4*II)+1));
Prod5_IDat1 = Prod5_Data1(:,((3*II)+2):((4*II)+1));
Prod6_IDat1 = Prod6_Data1(:,((3*II)+2):((4*II)+1));
Prod7_IDat1 = Prod7_Data1(:,((3*II)+2):((4*II)+1));
Prod8_IDat1 = Prod8_Data1(:,((3*II)+2):((4*II)+1));

% COLLATING INPUT DATA FOR CRM + MACHINE LEARNING
Prod1_IDat2 = Prod1_Data1(:,1:((4*II)+2)); 
Prod2_IDat2 = Prod2_Data1(:,1:((4*II)+2));
Prod3_IDat2 = Prod3_Data1(:,1:((4*II)+2));
Prod4_IDat2 = Prod4_Data1(:,1:((4*II)+2));
Prod5_IDat2 = Prod5_Data1(:,1:((4*II)+2));
Prod6_IDat2 = Prod6_Data1(:,1:((4*II)+2));
Prod7_IDat2 = Prod7_Data1(:,1:((4*II)+2));
Prod8_IDat2 = Prod8_Data1(:,1:((4*II)+2));

% COLLATING OUTPUT DATA
Prod1_OData = Prod1_Data1(:,((4*II)+3));
Prod2_OData = Prod2_Data1(:,((4*II)+3));
Prod3_OData = Prod3_Data1(:,((4*II)+3));
Prod4_OData = Prod4_Data1(:,((4*II)+3));
Prod5_OData = Prod5_Data1(:,((4*II)+3));
Prod6_OData = Prod6_Data1(:,((4*II)+3));
Prod7_OData = Prod7_Data1(:,((4*II)+3));
Prod8_OData = Prod8_Data1(:,((4*II)+3));

clear GG i1 j1 i2 j2 i3 j3 i4 j4 i5 j5 i6 j6 i7 j7 i8 j8

% Producers' Production Rates used in Denormalizing
Prod1_O = Prod1_Data(:,(4*II)+3);   Prod2_O = Prod2_Data(:,(4*II)+3);
Prod3_O = Prod3_Data(:,(4*II)+3);   Prod4_O = Prod4_Data(:,(4*II)+3);
Prod5_O = Prod5_Data(:,(4*II)+3);   Prod6_O = Prod6_Data(:,(4*II)+3);
Prod7_O = Prod7_Data(:,(4*II)+3);   Prod8_O = Prod8_Data(:,(4*II)+3);

%% TRAINING AND PREDICTIONS USING SVM AND CRM-SVM

slv = 'SMO';        % Solver for SVMs

% SVM
 % Training the SVMs
 SVM1 = fitrsvm(Prod1_IDat1(1:NNA,:),Prod1_OData(1:NNA),'Solver',slv);
 SVM2 = fitrsvm(Prod2_IDat1(1:NNA,:),Prod2_OData(1:NNA),'Solver',slv);
 SVM3 = fitrsvm(Prod3_IDat1(1:NNA,:),Prod3_OData(1:NNA),'Solver',slv);
 SVM4 = fitrsvm(Prod4_IDat1(1:NNA,:),Prod4_OData(1:NNA),'Solver',slv);
 SVM5 = fitrsvm(Prod5_IDat1(1:NNA,:),Prod5_OData(1:NNA),'Solver',slv);
 SVM6 = fitrsvm(Prod6_IDat1(1:NNA,:),Prod6_OData(1:NNA),'Solver',slv);
 SVM7 = fitrsvm(Prod7_IDat1(1:NNA,:),Prod7_OData(1:NNA),'Solver',slv);
 SVM8 = fitrsvm(Prod8_IDat1(1:NNA,:),Prod8_OData(1:NNA),'Solver',slv);
 
 % Predictions using SVMs, yielding Normalized Production Rates
 P1_SVM1 = predict(SVM1,Prod1_IDat1);
 P2_SVM1 = predict(SVM2,Prod2_IDat1);
 P3_SVM1 = predict(SVM3,Prod3_IDat1);
 P4_SVM1 = predict(SVM4,Prod4_IDat1);
 P5_SVM1 = predict(SVM5,Prod5_IDat1);
 P6_SVM1 = predict(SVM6,Prod6_IDat1);
 P7_SVM1 = predict(SVM7,Prod7_IDat1);
 P8_SVM1 = predict(SVM8,Prod8_IDat1);

 % Denormalizing the Predicted Production Rates from SVMs
 P1_SVM2 = (P1_SVM1.*(max(Prod1_O)-min(Prod1_O)))+min(Prod1_O);
 P2_SVM2 = (P2_SVM1.*(max(Prod2_O)-min(Prod2_O)))+min(Prod2_O);
 P3_SVM2 = (P3_SVM1.*(max(Prod3_O)-min(Prod3_O)))+min(Prod3_O);
 P4_SVM2 = (P4_SVM1.*(max(Prod4_O)-min(Prod4_O)))+min(Prod4_O);
 P5_SVM2 = (P5_SVM1.*(max(Prod5_O)-min(Prod5_O)))+min(Prod5_O);
 P6_SVM2 = (P6_SVM1.*(max(Prod6_O)-min(Prod6_O)))+min(Prod6_O);
 P7_SVM2 = (P7_SVM1.*(max(Prod7_O)-min(Prod7_O)))+min(Prod7_O);
 P8_SVM2 = (P8_SVM1.*(max(Prod8_O)-min(Prod8_O)))+min(Prod8_O);

% CRM-SVM
 % Training the CRM-SVMs
 CRM_SVM1 = fitrsvm(Prod1_IDat2(1:NNA,:),Prod1_OData(1:NNA),'Solver',slv);
 CRM_SVM2 = fitrsvm(Prod2_IDat2(1:NNA,:),Prod2_OData(1:NNA),'Solver',slv);
 CRM_SVM3 = fitrsvm(Prod3_IDat2(1:NNA,:),Prod3_OData(1:NNA),'Solver',slv);
 CRM_SVM4 = fitrsvm(Prod4_IDat2(1:NNA,:),Prod4_OData(1:NNA),'Solver',slv);
 CRM_SVM5 = fitrsvm(Prod5_IDat2(1:NNA,:),Prod5_OData(1:NNA),'Solver',slv);
 CRM_SVM6 = fitrsvm(Prod6_IDat2(1:NNA,:),Prod6_OData(1:NNA),'Solver',slv);
 CRM_SVM7 = fitrsvm(Prod7_IDat2(1:NNA,:),Prod7_OData(1:NNA),'Solver',slv);
 CRM_SVM8 = fitrsvm(Prod8_IDat2(1:NNA,:),Prod8_OData(1:NNA),'Solver',slv);
 
 % Predicting using CRM-SVMs, yielding Normalized Production Rates
 P1_CRM_SVM1 = predict(CRM_SVM1,Prod1_IDat2);
 P2_CRM_SVM1 = predict(CRM_SVM2,Prod2_IDat2);
 P3_CRM_SVM1 = predict(CRM_SVM3,Prod3_IDat2);
 P4_CRM_SVM1 = predict(CRM_SVM4,Prod4_IDat2);
 P5_CRM_SVM1 = predict(CRM_SVM5,Prod5_IDat2);
 P6_CRM_SVM1 = predict(CRM_SVM6,Prod6_IDat2);
 P7_CRM_SVM1 = predict(CRM_SVM7,Prod7_IDat2);
 P8_CRM_SVM1 = predict(CRM_SVM8,Prod8_IDat2);

 % Denormalizing the Predicted Production Rates from CRM-SVMs
 P1_CRM_SVM2 = (P1_CRM_SVM1.*(max(Prod1_O)-min(Prod1_O)))+min(Prod1_O);
 P2_CRM_SVM2 = (P2_CRM_SVM1.*(max(Prod2_O)-min(Prod2_O)))+min(Prod2_O);
 P3_CRM_SVM2 = (P3_CRM_SVM1.*(max(Prod3_O)-min(Prod3_O)))+min(Prod3_O);
 P4_CRM_SVM2 = (P4_CRM_SVM1.*(max(Prod4_O)-min(Prod4_O)))+min(Prod4_O);
 P5_CRM_SVM2 = (P5_CRM_SVM1.*(max(Prod5_O)-min(Prod5_O)))+min(Prod5_O);
 P6_CRM_SVM2 = (P6_CRM_SVM1.*(max(Prod6_O)-min(Prod6_O)))+min(Prod6_O);
 P7_CRM_SVM2 = (P7_CRM_SVM1.*(max(Prod7_O)-min(Prod7_O)))+min(Prod7_O);
 P8_CRM_SVM2 = (P8_CRM_SVM1.*(max(Prod8_O)-min(Prod8_O)))+min(Prod8_O);
    
clear slv SVM1 SVM2 SVM3 SVM4 SVM5 SVM6 SVM7 SVM8 CRM_SVM1 CRM_SVM2 ...
    CRM_SVM3 CRM_SVM4 CRM_SVM5 CRM_SVM6 CRM_SVM7 CRM_SVM8 P1_SVM1 P2_SVM1 ...
    P3_SVM1 P4_SVM1 P5_SVM1 P6_SVM1 P7_SVM1 P8_SVM1 P1_CRM_SVM1 P2_CRM_SVM1 ...
    P3_CRM_SVM1 P4_CRM_SVM1 P5_CRM_SVM1 P6_CRM_SVM1 P7_CRM_SVM1 P8_CRM_SVM1
   