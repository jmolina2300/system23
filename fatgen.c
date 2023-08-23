#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>


#define FAT16_RESERVED_BYTES  4
#define FAT12_RESERVED_BYTES  3

#define BPB_START_OFFSET  3
#define BPB_SIZE_FAT12    0x3A
#define BPB_SIZE_FAT16    BPB_SIZE_FAT12

typedef enum {T_FAT12, T_FAT16, T_FAT32} fat_t;

/* DOS  BPB for FAT12 and FAT16 */
struct bpb_fat12 {
    char     BS_OEMName[8 + 1];
    uint16_t BPB_BytesPerSec;
    uint8_t  BPB_SecPerClus;
    uint16_t BPB_RsvdSecCnt;
    uint8_t  BPB_NumFATs;
    uint16_t BPB_RootEntCnt;
    uint16_t BPB_TotSec16;
    uint8_t  BPB_Media;
    uint16_t BPB_FATsz;          /* FAT size in sectors */
    uint16_t BPB_SecPerTrk;
    uint16_t BPB_NumHeads;
    uint32_t BPB_HiddSec;
    uint32_t BPB_TotSec32;
    uint8_t  BS_DrvNum;
    uint8_t  BS_Reserved1;
    uint8_t  BS_BootSig;
    uint32_t BS_VolID;
    char     BS_VolLab[11 + 1];
    char     BS_FilSysType[8 + 1];
};


/*
   fat_print_info

   Print out the BPB information for FAT12/16 volume

 */
void fat_print_info(struct bpb_fat12 *bpb) 
{
    printf("Volume Information for \"%s\"\n", bpb->BS_VolLab);
    printf("========================================\n");
    printf("    BPB_BytesPerSec: %d\n", bpb->BPB_BytesPerSec);
    printf("     BPB_SecPerClus: %d\n", bpb->BPB_SecPerClus);
    printf("     BPB_RsvdSecCnt: %d\n", bpb->BPB_RsvdSecCnt);
    printf("        BPB_NumFATs: %d\n", bpb->BPB_NumFATs);
    printf("     BPB_RootEntCnt: %d\n", bpb->BPB_RootEntCnt);
    printf("       BPB_TotSec16: %d\n", bpb->BPB_TotSec16);
    printf("          BPB_Media: 0x%X\n", bpb->BPB_Media);
    printf("          BPB_FATsz: %d\n", bpb->BPB_FATsz);
    printf("      BPB_SecPerTrk: %d\n", bpb->BPB_SecPerTrk);
    printf("       BPB_NumHeads: %d\n", bpb->BPB_NumHeads);
    printf("        BPB_HiddSec: %d\n", bpb->BPB_HiddSec);
    printf("          BS_DrvNum: %d\n", bpb->BS_DrvNum);
    printf("       BS_Reserved1: %d\n", bpb->BS_Reserved1);
    printf("         BS_BootSig: 0x%02x\n", bpb->BS_BootSig);
    printf("           BS_VolID: %d\n", bpb->BS_VolID);
    printf("          BS_VolLab: %11s\n", bpb->BS_VolLab);
    printf("      BS_FilSysType: %8s\n", bpb->BS_FilSysType);
}


/* 
   fat_read_info
  
   The BPB structure will not have ALL fields filled.

   TotalSectors16 OR TotalSectors32 should be filled out, but not both.

*/
int fat_read_info(struct bpb_fat12 *bpb, FILE *fp)
{
    fseek(fp, BPB_START_OFFSET, SEEK_SET);
    fread(&bpb->BS_OEMName, sizeof(char), 8, fp);
    fread(&bpb->BPB_BytesPerSec, sizeof(uint16_t), 1, fp);
    fread(&bpb->BPB_SecPerClus, sizeof(uint8_t), 1, fp);
    fread(&bpb->BPB_RsvdSecCnt, sizeof(uint16_t), 1, fp);
    fread(&bpb->BPB_NumFATs, sizeof(uint8_t), 1, fp);
    fread(&bpb->BPB_RootEntCnt, sizeof(uint16_t), 1, fp);
    fread(&bpb->BPB_TotSec16, sizeof(uint16_t), 1, fp);
    fread(&bpb->BPB_Media, sizeof(uint8_t), 1, fp);
    fread(&bpb->BPB_FATsz, sizeof(uint16_t), 1, fp);

    fread(&bpb->BPB_SecPerTrk, sizeof(uint16_t), 1, fp);
    fread(&bpb->BPB_NumHeads, sizeof(uint16_t), 1, fp);
    fread(&bpb->BPB_HiddSec, sizeof(uint32_t), 1, fp);
    fread(&bpb->BPB_TotSec32, sizeof(uint32_t), 1, fp);

    fread(&bpb->BS_DrvNum, sizeof(uint8_t), 1, fp);
    fread(&bpb->BS_Reserved1, sizeof(uint8_t), 1, fp);
    fread(&bpb->BS_BootSig, sizeof(uint8_t), 1, fp);
    fread(&bpb->BS_VolID, sizeof(uint32_t), 1, fp);
    fread(&bpb->BS_VolLab, sizeof(char), 11, fp);
    fread(&bpb->BS_FilSysType, sizeof(char), 8, fp);
    bpb->BS_OEMName[8] = '\0';
    bpb->BS_VolLab[11] = '\0';
    bpb->BS_FilSysType[8] = '\0';


    /* Check to make sure we just read a valid BPB... */

    
    if (bpb->BPB_BytesPerSec % 2) {
        return -1;
    }

    /* If totalsectors16 is 0, then totalsectors32 must be non-zero */
    if (bpb->BPB_TotSec16 == 0 && bpb->BPB_TotSec32 == 0) {
        return -1;
    }

    /* If totalsectors16 is non-zero, then totalsectors32 must be 0 */
    if (bpb->BPB_TotSec16 != 0 && bpb->BPB_TotSec32 != 0) {
        return -1;
    }

    return 0;
}


/* fat_get_type
 *
 * Determine the type of FAT by the count of clusters
 * 
*/
fat_t fat_get_type(struct bpb_fat12 *bpb)
{
    /* The type of FAT is determined solely by the count of clusters
       on the volume (Microsoft specification).
     
       1. Determine the count of sectors occupied by the root driectory

       2. Determine the count of sectors in the data region of the volume

       3. Determine the total count of clusters
    
    */
    uint16_t RootDirSectors = ((bpb->BPB_RootEntCnt * 32) + (bpb->BPB_BytesPerSec - 1)) / bpb->BPB_BytesPerSec;
    
    uint32_t TotSec, DataSec, CountofClusters;
    uint16_t FATSz = bpb->BPB_FATsz;

    if (bpb->BPB_TotSec16 != 0) {
        TotSec = bpb->BPB_TotSec16;
    } else {
        TotSec = bpb->BPB_TotSec32;
    }

    DataSec = TotSec - (bpb->BPB_RsvdSecCnt + (bpb->BPB_NumFATs * FATSz) + RootDirSectors);

    CountofClusters = DataSec / bpb->BPB_SecPerClus;

    if (CountofClusters < 4085) {
        return T_FAT12;
    } else if (CountofClusters < 65525) {
        return T_FAT16;
    } else {
        return T_FAT32;
    }

}


/* fat_write
 *
 * Determine the FAT size in bytes and then write that number
 * of bytes minus the reserved bytes at the beginning of the FAT.
 * 
*/
void fat_write(struct bpb_fat12 *bpb, FILE *fp)
{
    
    uint32_t fat_size_bytes = bpb->BPB_FATsz * bpb->BPB_BytesPerSec;
    uint8_t fat16_rsvd[FAT16_RESERVED_BYTES] = {0xF8, 0xFF, 0xFF, 0xFF};
    uint8_t fat12_rsvd[FAT12_RESERVED_BYTES] = {0xF0, 0xFF, 0xFF};

    /* Write the reserved bytes at the beginning of the FAT */

    fat_t type = fat_get_type(bpb);
    if (type == T_FAT16) {
        fat_size_bytes -= FAT16_RESERVED_BYTES;
        fwrite(fat16_rsvd, sizeof(fat16_rsvd), 1, fp);
        
    } else if (type == T_FAT12) {
        fat_size_bytes -= FAT12_RESERVED_BYTES;
        fwrite(fat12_rsvd, sizeof(fat12_rsvd), 1, fp);

    } else {
        printf("Error: FAT32 not supported\n");
        exit(1);
    }


    /* Write the remaining bytes of the FAT */
    uint32_t bytes_written = 0;
    uint32_t bytes_remaining = fat_size_bytes;

    while (bytes_written < bytes_remaining) {
        uint8_t zero = 0x00;
        bytes_written += fwrite(&zero, sizeof(uint8_t), 1, fp);
    }
}


/*
 * fat_generate
 * 
 * Write the number of FATs specified in the bpb
 * 
*/
void fat_generate(struct bpb_fat12 *bpb, FILE *fp)
{
    uint32_t fats_remaining = bpb->BPB_NumFATs;

    while (fats_remaining > 0) 
    {
        fat_write(bpb, fp);
        fats_remaining--;
    }
}


void fat_create_root_dir(struct bpb_fat12 *bpb, FILE *fp)
{
    uint32_t root_dir_sectors =  ((bpb->BPB_RootEntCnt * 32) + (bpb->BPB_BytesPerSec - 1)) / bpb->BPB_BytesPerSec;
    uint32_t bytes_written = 0;
    uint32_t bytes_remaining = root_dir_sectors * bpb->BPB_BytesPerSec;

    while (bytes_written < bytes_remaining) {
        uint8_t zero = 0x00;
        bytes_written += fwrite(&zero, sizeof(uint8_t), 1, fp);
    }
}



int main(int argc, char **argv) 
{
    FILE *fp;
    struct bpb_fat12 bpb;
    int valid_fat = 0;
    
    if (argc < 2) {
        fp = stdin;
    } else if (argc == 2) {
        fp = fopen(argv[1], "rb");
        if (fp == NULL) {
            printf("Error: could not open %s\n", argv[1]);
            exit(1);
        }
    } else {
        printf("Usage: fatgen [disk_image]\n");
        exit(1);
    }

    
    /* Read the BIOS parameter block   */
    if (fat_read_info(&bpb, fp) != 0) {
        printf("Error: invalid FAT BPB\n");
        //exit(1);
    }
    fclose(fp);
    fat_print_info(&bpb);
    printf("\n");

    /* Generate the FAT   */
    printf("Generating FAT...");
    FILE *output = fopen("fat.bin", "wb");
    fat_generate(&bpb, output);
    /*fat_create_root_dir(&bpb, output);    */
    fclose(output);

    printf("Done!\n");
    
    return valid_fat;
}
