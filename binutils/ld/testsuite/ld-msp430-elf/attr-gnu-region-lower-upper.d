#name: prevent merging of lower and upper attributes
#source: attr-gnu-main.s -ml -mdata-region=lower
#source: attr-gnu-obj.s -ml -mdata-region=upper
#ld:
#error: .*uses the upper region for data, but.*assumes data is in lower memory.*
#error: .*failed to merge target specific data of file.*
