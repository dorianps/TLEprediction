% this program calculates the pet values (mesial and lateral, + entire TL
% and hippo) using the file MasterBatch.mat to know which subjects to
% calculate. MasterBatch is the batch of coregistration used one step
% before. This program then updates the variable FreesurferList with the
% new subjects, saves it, and copies the columns with values in the
% clipboard for a ready paste in excel.
% REMEMBER: positive lateralities show righward bias, so may indicate left
% TL hypometabolism, and viceversa.

% mesial temporal lobe
% LEFT hemisphere
Lhip=17;
Lamyg=18;
Lentorhinal=1006;
Lparahip=1016;
% RIGHT hemisphere
Rhip=53;
Ramyg=54;
Rentorhinal=2006;
Rparahip=2016;

% lateral temporal lobe
% LEFT hemisphere
Linftemp=1009;
Lmidtemp=1015;
Lsuptemp=1030;
% RIGHT hemisphere
Rinftemp=2009;
Rmidtemp=2015;
Rsuptemp=2030;


templatedir = [fileparts( which(mfilename) ) filesep];



% PET file
[filename, pathname] = uigetfile('*.nii', 'Select PET volume:');
if isequal(filename,0)
   disp('User selected Cancel')
   return;
else
   PETfile = [pathname filename];
   PETdir = pathname;
end

% T1 file
[filename, pathname] = uigetfile('*.nii', 'Select T1 volume:');
if isequal(filename,0)
   disp('User selected Cancel')
   return;
else
   MRIfile = [pathname filename];
   MRIdir = pathname;
end

% wmparc file
[filename, pathname] = uigetfile('*.nii', 'Select parcellation volume wmparc:');
if isequal(filename,0)
   disp('User selected Cancel')
   return;
else
   PARCfile = [pathname filename];
   PARCdir = pathname;
end



   %% get the pet and calculate new header matrix from center of mass
    orig = spm_vol(PETfile);
    mat = orig.mat;
    img=spm_read_vols(orig);
    centervx = centerOfMass(double(img));
    centermm = centervx.*[mat(1,1) mat(2,2) mat(3,3)];
    shifts = round(-(centermm'+mat(1:3,4))); % difference where is and where should be the center
    newmat = eye(4,4);                       % the reorientation matrix
    newmat(1:3,4) = shifts;                   % keep all but last column unchanged (1 in diagonal)

    
    [temp newPETfile ext] = fileparts(PETfile);
    PETfile001 = [PETdir 'on001-' newPETfile ext];
    if exist([PETfile001]) ~= 2    
        % load batch for rorientation and apply the newmat transformation
        load([templatedir 'reorienttemplate.mat']);
        matlabbatch{1, 1}.spm.util.reorient.srcfiles{1, 1} = [PETfile ',1']; % dont forget ,1 at the end
        matlabbatch{1, 1}.spm.util.reorient.transform.transM = newmat;
        spm_jobman('initcfg');
        spm_jobman('run',matlabbatch);
        save([PETdir 'PETsetOriginToCenter.mat'], 'matlabbatch');

        % load batch to coregister PET to MRI and run
        load([templatedir 'coregistertemplate.mat']);
        matlabbatch{1, 1}.spm.spatial.coreg.estwrite.ref{1, 1} = [MRIfile ',1']; % don't forget the ,1
        matlabbatch{1, 1}.spm.spatial.coreg.estwrite.source{1, 1} = [PETfile ',1']; % don't forget the ,1
        spm_jobman('initcfg');
        spm_jobman('run',matlabbatch);
        save([PETdir '\CoregisterPETtoMRI.mat'], 'matlabbatch');
    else
        disp('Using existing coregistered PET file')
    end
 
    
    % reslice wmaparc.nii onto PET 001
    [temp newPARCfile ext] = fileparts(PARCfile);
    PARCfile001 = [PARCdir 'onPET001-' newPARCfile ext];
    if exist([PARCfile001]) ~= 2
        load([templatedir 'ResliceWMparcTemplateJob.mat']);
        matlabbatch{1, 1}.spm.spatial.coreg.write.ref{1}  = [PETfile001 ',1']; % PET image
        matlabbatch{1, 1}.spm.spatial.coreg.write.source{1} = [PARCfile ',1'];         % parcellation image
        save([PARCdir 'ResliceWMparcTo001.mat'], 'matlabbatch');
        spm_jobman('initcfg');
        spm_jobman('run',matlabbatch);
    else
        disp('Using existing resliced parcellation file')
    end
    
    
    
    %% ALL FILES READY, START PROCESSING
    %% Create the smoothed versions of the parcellations
    vol = spm_vol(spm_vol(PARCfile001));
    vol.dt = [16 0];
    aparc = spm_read_vols(spm_vol(PARCfile001)); % load wmparc.nii

    % lateral TL left
    if exist([PETdir 'newMaskTLlateralL.nii']) == 2, MaskTLlateralL = spm_read_vols(spm_vol([PETdir 'newMaskTLlateralL.nii']));
    else
        tempvar = zeros(size(aparc));
        tempvar(aparc==Linftemp | aparc==Lmidtemp | aparc==Lsuptemp) = 1;
        spm_smooth(tempvar, tempvar, [8 8 8], 'float');
        vol.fname = [PETdir 'newMaskTLlateralL.nii'];
        spm_write_vol(vol,tempvar);
        MaskTLlateralL = tempvar;
    end
    % lateral TL right
    if exist([PETdir 'newMaskTLlateralR.nii']) == 2, MaskTLlateralR = spm_read_vols(spm_vol([PETdir 'newMaskTLlateralR.nii']));
    else
        tempvar = zeros(size(aparc));
        tempvar(aparc==Rinftemp | aparc==Rmidtemp | aparc==Rsuptemp) = 1;
        spm_smooth(tempvar, tempvar, [8 8 8], 'float');
        vol.fname = [PETdir 'newMaskTLlateralR.nii'];
        spm_write_vol(vol,tempvar);
        MaskTLlateralR = tempvar;
    end
    % mesial cortex left
    if exist([PETdir 'newMaskTLmesialL.nii']) == 2, MaskTLmesialL = spm_read_vols(spm_vol([PETdir 'newMaskTLmesialL.nii']));
    else
        tempvar = zeros(size(aparc));
        tempvar(aparc==Lentorhinal | aparc==Lparahip | aparc==Lhip | aparc==Lamyg) = 1;
        spm_smooth(tempvar, tempvar, [8 8 8], 'float');
        vol.fname = [PETdir 'newMaskTLmesialL.nii'];
        spm_write_vol(vol,tempvar);
        MaskTLmesialL = tempvar;
    end
    % mesial cortex right
    if exist([PETdir 'newMaskTLmesialR.nii']) == 2, MaskTLmesialR = spm_read_vols(spm_vol([PETdir 'newMaskTLmesialR.nii']));
    else
        tempvar = zeros(size(aparc));
        tempvar(aparc==Rentorhinal | aparc==Rparahip | aparc==Rhip | aparc==Ramyg) = 1;
        spm_smooth(tempvar, tempvar, [8 8 8], 'float');
        vol.fname = [PETdir 'MaskTLmesialRfixed.nii'];
        spm_write_vol(vol,tempvar);
        MaskTLmesialR = tempvar;
    end
    % Hippo left
    if exist([PETdir 'newMaskTLhippoL.nii']) == 2, MaskTLhippoL = spm_read_vols(spm_vol([PETdir 'newMaskTLhippoL.nii']));
    else
        tempvar = zeros(size(aparc));
        tempvar(aparc==Lhip) = 1;
        spm_smooth(tempvar, tempvar, [8 8 8], 'float');
        vol.fname = [PETdir 'newMaskTLhippoL.nii'];
        spm_write_vol(vol,tempvar);
        MaskTLhippoL = tempvar;
    end
    % Hippo right
    if exist([PETdir 'newMaskTLhippoR.nii']) == 2, MaskTLhippoR = spm_read_vols(spm_vol([PETdir 'newMaskTLhippoR.nii']));
    else
        tempvar = zeros(size(aparc));
        tempvar(aparc==Rhip) = 1;
        spm_smooth(tempvar, tempvar, [8 8 8], 'float');
        vol.fname = [PETdir 'newMaskTLhippoR.nii'];
        spm_write_vol(vol,tempvar);
        MaskTLhippoR = tempvar;
    end
    % entire left TL
    if exist([PETdir 'newMaskTLentireL.nii']) == 2, MaskTLentireL = spm_read_vols(spm_vol([PETdir 'newMaskTLentireL.nii']));
    else
        tempvar = zeros(size(aparc));
        tempvar(aparc==Linftemp | aparc==Lmidtemp | aparc==Lsuptemp | aparc==Lentorhinal | aparc==Lparahip | aparc==Lhip | aparc==Lamyg) = 1;
        spm_smooth(tempvar, tempvar, [8 8 8], 'float');
        vol.fname = [PETdir 'newMaskTLentireL.nii'];
        spm_write_vol(vol,tempvar);
        MaskTLentireL = tempvar;
    end
    % entire right TL
    if exist([PETdir 'newMaskTLentireR.nii']) == 2, MaskTLentireR = spm_read_vols(spm_vol([PETdir 'newMaskTLentireR.nii']));
    else
        tempvar = zeros(size(aparc));
        tempvar(aparc==Rinftemp | aparc==Rmidtemp | aparc==Rsuptemp | aparc==Rentorhinal | aparc==Rparahip | aparc==Rhip | aparc==Ramyg) = 1;
        spm_smooth(tempvar, tempvar, [8 8 8], 'float');
        vol.fname = [PETdir 'newMaskTLentireR.nii'];
        spm_write_vol(vol,tempvar);
        MaskTLentireR = tempvar;
    end

    

    % get the pet image
    pet = spm_read_vols(spm_vol(PETfile001));
    

  
    %% start calculating weighted average of PET, and their lateralities
    % LATERAL
    
%     mask = MaskTLlateralL;
%     left = sum(pet(mask>0.35).*mask(mask>0.35) / sum(mask(mask>0.35)) );
%     mask = MaskTLlateralR;
%     right = sum(pet(mask>0.35).*mask(mask>0.35) / sum(mask(mask>0.35)) );
%     LateralLImean = (right-left)/sum([right left]); %%%%%%%%%%%%%%
%     mask = MaskTLlateralL;
%     left = var(nonzeros(pet(mask>0.35)), nonzeros(mask.*(mask>0.35)));
%     mask = MaskTLlateralR;
%     right = var(nonzeros(pet(mask>0.35)), nonzeros(mask.*(mask>0.35)));
%     LateralLIvar = (right-left)/sum([right left]); %%%%%%%%%%%%%%
%     mask = MaskTLlateralL;
%     left = kurtosis(nonzeros(pet(mask>0.35)));
%     mask = MaskTLlateralR;
%     right = kurtosis(nonzeros(pet(mask>0.35)));
%     LateralLIkurt = (right-left)/sum([abs(right) abs(left)]); %%%%%%%%%%%%
%     mask = MaskTLlateralL;
%     left = skewness(nonzeros(pet(mask>0.35)));
%     mask = MaskTLlateralR;
%     right = skewness(nonzeros(pet(mask>0.35)));
%     LateralLIskew = (right-left)/sum([abs(right) abs(left)]); %%%%%%%%%%%%%%%
    
    % MESIAL
        mask = MaskTLmesialL;
        left = sum(pet(mask>0.35).*mask(mask>0.35) / sum(mask(mask>0.35)) );
        mask = MaskTLmesialR;
        right = sum(pet(mask>0.35).*mask(mask>0.35) / sum(mask(mask>0.35)) );
        MesialLImean =  (right-left)/sum([right left]); %%%%%%%%%%%%%%
%     mask = MaskTLmesialL;
%     left = var(nonzeros(pet(mask>0.35)), nonzeros(mask.*(mask>0.35)));
%     mask = MaskTLmesialR;
%     right = var(nonzeros(pet(mask>0.35)), nonzeros(mask.*(mask>0.35)));
%     MesialLIvar = (right-left)/sum([right left]); %%%%%%%%%%%%%%%%%%%%%%
%     mask = MaskTLmesialL;
%     left = kurtosis(nonzeros(pet(mask>0.35)));
%     mask = MaskTLmesialR;
%     right = kurtosis(nonzeros(pet(mask>0.35)));
%     MesialLIkurt = (right-left)/sum([abs(right) abs(left)]); %%%%%%%%%%%%%%
%     mask = MaskTLmesialL;
%     left = skewness(nonzeros(pet(mask>0.35)));
%     mask = MaskTLmesialR;
%     right = skewness(nonzeros(pet(mask>0.35)));
%     MesialLIskew = (right-left)/sum([abs(right) abs(left)]); %%%%%%%%%%%%%%%%%%
    
    % HIPPO 
%     mask = MaskTLhippoL;
%     left = sum(pet(mask>0.35).*mask(mask>0.35) / sum(mask(mask>0.35)) );
%     mask = MaskTLhippoR;
%     right = sum(pet(mask>0.35).*mask(mask>0.35) / sum(mask(mask>0.35)) );
%     HippoLImean = (right-left)/sum([right left]); %%%%%%%%%%%%%%
        mask = MaskTLhippoL;
        left = var(nonzeros(pet(mask>0.35)), nonzeros(mask.*(mask>0.35)));
        mask = MaskTLhippoR;
        right = var(nonzeros(pet(mask>0.35)), nonzeros(mask.*(mask>0.35)));
        HippoLIvar = (right-left)/sum([right left]); %%%%%%%%%%%%%%%%%%%
%     mask = MaskTLhippoL;
%     left = kurtosis(nonzeros(pet(mask>0.35)));
%     mask = MaskTLhippoR;
%     right = kurtosis(nonzeros(pet(mask>0.35)));
%     HippoLIkurt = (right-left)/sum([abs(right) abs(left)]);   %%%%%%%%%%%%%%%%%%%%
%     mask = MaskTLhippoL;
%     left = skewness(nonzeros(pet(mask>0.35)));
%     mask = MaskTLhippoR;
%     right = skewness(nonzeros(pet(mask>0.35)));
%     HippoLIskew = (right-left)/sum([abs(right) abs(left)]); %%%%%%%%%%%%%%%%%%%%%%
    
%     % ENTIRE TL
%     mask = MaskTLentireL;
%     left = sum(pet(mask>0.35).*mask(mask>0.35) / sum(mask(mask>0.35)) );
%     mask = MaskTLentireR;
%     right = sum(pet(mask>0.35).*mask(mask>0.35) / sum(mask(mask>0.35)) );
%     EntireLImean = (right-left)/sum([right left]); %%%%%%%%%%%%%%
        mask = MaskTLentireL;
        left = var(nonzeros(pet(mask>0.35)), nonzeros(mask.*(mask>0.35)));
        mask = MaskTLentireR;
        right = var(nonzeros(pet(mask>0.35)), nonzeros(mask.*(mask>0.35)));
        EntireLIvar = (right-left)/sum([right left]); %%%%%%%%%%%%%%%%%%%%%%%%
%     mask = MaskTLentireL;
%     left = kurtosis(nonzeros(pet(mask>0.35)));
%     mask = MaskTLentireR;
%     right = kurtosis(nonzeros(pet(mask>0.35)));
%     EntireLIkurt = (right-left)/sum([abs(right) abs(left)]); %%%%%%%%%%%%%%%%%%%%%%%
%     mask = MaskTLentireL;
%     left = skewness(nonzeros(pet(mask>0.35)));
%     mask = MaskTLentireR;
%     right = skewness(nonzeros(pet(mask>0.35)));
%     EntireLIskew = (right-left)/sum([abs(right) abs(left)]); %%%%%%%%%%%%%
    
    
    

    %% we have the 3 values, display them
    disp(['PET file: ' PETfile001])
    disp(['MRI file: ' MRIfile])
    disp(['Parcel file: ' PARCfile001])
    disp('::ASYMMETRIES::')
    disp(['PET-mesial: ' num2str(MesialLImean)])
    disp(['PET-hippo-var: ' num2str(HippoLIvar)])
    disp(['PET-entire-var: ' num2str(EntireLIvar)])
    disp('VALUES VALID IF PET IS CORRECTLY REGISTERED WITH MRI. PLEASE CHECK!')