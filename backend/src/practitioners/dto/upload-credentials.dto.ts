import { IsArray, IsString } from 'class-validator';

export class UploadCredentialsDto {
  @IsArray()
  @IsString({ each: true })
  credentialFiles: string[]; // S3 file keys
}
