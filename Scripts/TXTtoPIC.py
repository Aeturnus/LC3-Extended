filename = input("Specify file (.txt):: ")
f = open(filename + ".txt","r");
filecont = f.read()
f.close
print("Input:\n" + filecont + "\n")
clinput = input("Treat spaces as transparency?[y,n]:: ")
if(clinput == 'y'):
    trans = True
    print("Spaces ARE transparent\n")
else:
    trans = False
    print("Spaces are NOT transparent\n")

clinput = input("Enable row compression (not implemented yet)?[y,n]:: ")
if(clinput == 'y'):
    comp = True
    print("Compression algorithm ENABLED\n")
else:
    comp = False
    print("Compressiong algorithm DISABLED\n")

fileout = (";" +  filename + "\n")

#Find the dimensions of the pic
i = 0
widths = []
widthsIndex = 1
rowwidth = 0
width = 0
height = 1
length = len(filecont)
while(i<length):
    currentChar = filecont[i]
    if(currentChar == '\n'):
        height += 1
        widths.append(rowwidth)
        rowwidth = 0
    else:
        rowwidth += 1
    i += 1
widthslen = len(widths)
i = 0
while(i<widthslen):
    if(widths[i] > width):
        width = widths[i]
    i += 1
fileout += ("\t.FILL\t" + str(width) + "\n")
fileout += ("\t.FILL\t" + str(height) + "\n")
#

currentChar = 0;
i = 0
left = True
while(i<length):
    currentChar = filecont[i]
    if(trans):
        if(currentChar == ' '):
            currentChar = "\0"
    if(currentChar != '\n'):    #skip newlines
        if(left):
            left = False
            fileout += ("\t.FILL\tx" + "{0:02x}".format(ord(currentChar)))
        else:
            left = True
            fileout += ("{0:02x}".format(ord(currentChar)) +"\n")
    i += 1
if(left == False):
    fileout += ("00\n")
fileout += ("\t.FILL\tx0303\n")

print("Output:\n" + fileout)
f = open(filename+".asm","w")
f.write(fileout)

input("Press 'enter' or 'return' to exit...")
